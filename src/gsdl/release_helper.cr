require "option_parser"
require "file_utils"
require "yaml"

# GSDL Release Helper
# Automates the creation of distribution-ready packages for macOS, Windows, and Linux.

module GSDL
  class ReleaseHelper
    @game : String = "game"
    @src : String = ""
    @target : String = ""
    @app_name : String = ""
    @version : String = ""
    @icon_path : String = ""
    @bundle_id : String = ""
    @output_dir : String = "build/release"
    @build_dir : String = "build"
    @assets_pack : String = "build/assets.pack"
    @target : String = ""
    @arch : String = ""
    @app_name : String = ""

    def initialize
      @target = detect_platform
      @arch = detect_arch
      parse_options
      @src = "src/main.cr" if @src.empty?
      @app_name = @game if @app_name.empty?
      @version = fetch_version if @version.empty?
      @bundle_id = "com.gsdl.#{@app_name.downcase.gsub(' ', '-')}" if @bundle_id.empty?
    end

    def detect_platform
      {% if flag?(:darwin) %}
        "mac"
      {% elsif flag?(:win32) %}
        "win"
      {% else %}
        "linux"
      {% end %}
    end

    def detect_arch
      {% if flag?(:aarch64) || flag?(:arm) %}
        "arm64"
      {% elsif flag?(:x86_64) %}
        "x86_64"
      {% else %}
        "unknown"
      {% end %}
    end

    def parse_options
      OptionParser.parse do |parser|
        parser.banner = "Usage: crystal src/gsdl/release_helper.cr -- [arguments]"
        parser.on("-e GAME", "--game=NAME", "Game to package (default: 'game')") { |game| @game = game }
        parser.on("-s PATH", "--src=PATH", "Source file path (default: src/<game>.cr)") { |path| @src = path }
        parser.on("-t TARGET", "--target=TARGET", "Target platform (mac, win, linux)") { |t| @target = t }
        parser.on("-n NAME", "--name=NAME", "App name (default: game name)") { |n| @app_name = n }
        parser.on("-v VER", "--version=VER", "App version (default: from shard.yml)") { |v| @version = v }
        parser.on("-i PATH", "--icon=PATH", "Icon file path") { |path| @icon_path = path }
        parser.on("-b ID", "--bundle-id=ID", "macOS Bundle ID (e.g., com.mygame.app)") { |id| @bundle_id = id }
        parser.on("-o DIR", "--output=DIR", "Output directory (default: 'build/release')") { |dir| @output_dir = dir }
        parser.on("-h", "--help", "Show this help") do
          puts parser
          exit
        end
      end
    end

    def fetch_version
      if File.exists?("shard.yml")
        shard = YAML.parse(File.read("shard.yml"))
        shard["version"].as_s
      else
        "0.1.0"
      end
    end

    def run
      puts "--- GSDL Release Helper ---"
      puts "Game:      #{@game}"
      puts "Source:    #{@src}"
      puts "Target:    #{@target}"
      puts "Arch:      #{@arch}"
      puts "App Name:  #{@app_name}"
      puts "Version:   #{@version}"
      puts "Bundle ID: #{@bundle_id}" if @target == "mac"
      puts "Output:    #{@output_dir}"
      puts "---------------------------"

      # 1. Build the binary
      build_binary

      # 2. Pack assets
      pack_assets

      # 3. Package for platform
      case @target
      when "mac"
        package_mac
      when "win"
        package_win
      when "linux"
        package_linux
      else
        raise "Unsupported target: #{@target}"
      end

      puts "\nSuccessfully created release package in #{@output_dir}"
    end

    private def build_binary
      puts "Building binary for #{@game}..."
      binary_path = File.join(@build_dir, @game)

      # Determine link flags
      link_flags = ""
      if @target == "win"
        # On Windows, we use the WINDOWS subsystem to suppress the console window
        # For MSVC linker (common with crystal on windows)
        link_flags = "--link-flags \"/SUBSYSTEM:WINDOWS\""
      elsif @target == "linux"
        # On Linux, we use $ORIGIN to look for libraries in the same directory as the binary
        # We escape the $ so it's not interpreted by the shell during the build command
        sdl3_mixer_lib_dir = "/usr/local/lib" # Default from Makefile
        link_flags = "--link-flags \"-L#{sdl3_mixer_lib_dir} -Wl,-rpath,'\\$ORIGIN'\""
      else
        # On macOS, we use rpath to find libraries
        sdl3_mixer_lib_dir = "/usr/local/lib" # Default from Makefile
        link_flags = "--link-flags \"-L#{sdl3_mixer_lib_dir} -Wl,-rpath,#{sdl3_mixer_lib_dir}\""
      end

      # Set deployment target to ensure compatibility with older macOS versions
      env = {} of String => String
      if @target == "mac"
        env["MACOSX_DEPLOYMENT_TARGET"] = "10.15"
      end

      cmd = "crystal build #{@src} -o #{binary_path} --release --no-debug #{link_flags} -p"
      puts "Running: #{cmd}"
      Process.run(cmd, shell: true, env: env).success? || raise "Failed to build binary"
    end

    private def pack_assets
      puts "Packing assets..."
      packer_bin = "bin/gsdl-packer"

      # Check if packer exists and is working (handles Exec format error)
      needs_build = !File.exists?(packer_bin)
      if !needs_build
        # Try to run it; if it fails, it might be the wrong architecture
        unless system("./#{packer_bin} --help > /dev/null 2>&1")
          puts "  Existing packer tool is incompatible or missing. Rebuilding..."
          needs_build = true
        end
      end

      if needs_build
        puts "  Building gsdl-packer..."
        packer_src = if File.exists?("src/packer.cr")
          "src/packer.cr"
        elsif File.exists?("lib/game_sdl/src/packer.cr")
          "lib/game_sdl/src/packer.cr"
        else
          raise "Could not find packer.cr"
        end
        system("crystal build #{packer_src} -o #{packer_bin} --release --no-debug -p") || raise "Failed to build packer"
      end

      system("./#{packer_bin}") || raise "Failed to pack assets"
    end

    private def package_mac
      puts "Packaging for macOS..."
      app_dir = File.join(@output_dir, "#{@app_name}.app")
      contents_dir = File.join(app_dir, "Contents")
      macos_dir = File.join(contents_dir, "MacOS")
      resources_dir = File.join(contents_dir, "Resources")

      FileUtils.mkdir_p(macos_dir)
      FileUtils.mkdir_p(resources_dir)

      # Copy binary
      FileUtils.cp(File.join(@build_dir, @game), File.join(macos_dir, @game))

      # Copy assets.pack
      FileUtils.cp(@assets_pack, File.join(resources_dir, "assets.pack"))

      # Create Info.plist
      plist_content = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
          <key>CFBundleExecutable</key>
          <string>#{@game}</string>
          <key>CFBundleGetInfoString</key>
          <string>#{@app_name} #{@version}</string>
          <key>CFBundleIconFile</key>
          <string>AppIcon</string>
          <key>CFBundleIdentifier</key>
          <string>#{@bundle_id}</string>
          <key>CFBundleInfoDictionaryVersion</key>
          <string>6.0</string>
          <key>CFBundleName</key>
          <string>#{@game}</string>
          <key>CFBundlePackageType</key>
          <string>APPL</string>
          <key>CFBundleShortVersionString</key>
          <string>#{@version}</string>
          <key>CFBundleSignature</key>
          <string>????</string>
          <key>CFBundleVersion</key>
          <string>#{@version}</string>
          <key>LSMinimumSystemVersion</key>
          <string>10.15</string>
          <key>NSPrincipalClass</key>
          <string>NSApplication</string>
          <key>NSHighResolutionCapable</key>
          <true/>
      </dict>
      </plist>
      XML
      File.write(File.join(contents_dir, "Info.plist"), plist_content)

      # Handle icon if @icon_path is provided
      if !@icon_path.empty? && File.exists?(@icon_path)
        FileUtils.cp(@icon_path, File.join(resources_dir, "AppIcon.icns"))
      end

      # Bundle libraries for macOS portability
      bundle_libraries_mac(macos_dir, contents_dir)

      # Create ZIP for macOS
      puts "Creating macOS ZIP archive..."
      # Use ./* inside the .app bundle is not right for macOS, usually we want the .app folder itself
      # but the user asked for "no root folder" for the zip.
      # Actually for macOS .app, you definitely WANT the .app folder.
      # But for Windows it makes sense to just have the files.
      zip_file_name = "#{@app_name.gsub(' ', '-')}-mac-#{@arch}-v#{@version}"
      system("cd #{@output_dir} && zip -r #{zip_file_name}.zip \"#{@app_name}.app\"")
    end

    private def bundle_libraries_mac(macos_dir, contents_dir)
      puts "Bundling dynamic libraries for macOS..."
      frameworks_dir = File.join(contents_dir, "Frameworks")
      FileUtils.mkdir_p(frameworks_dir)

      binary_path = "\"#{File.join(macos_dir, @game)}\""

      # 1. Add @executable_path/../Frameworks to rpath
      system("install_name_tool -add_rpath @executable_path/../Frameworks #{binary_path}")

      # 2. Find and copy libraries
      # We look for common SDL3 library paths from otool output
      output = `otool -L #{binary_path}`
      output.each_line do |line|
        line = line.strip
        next if line.empty? || line.starts_with?(binary_path)

        # Extract path (e.g., /opt/homebrew/opt/sdl3/lib/libSDL3.0.dylib)
        lib_path = line.split(' ')[0]

        # Skip system libraries
        next if lib_path.starts_with?("/usr/lib") || lib_path.starts_with?("/System")

        # If it's already an @rpath or @executable_path, we might still need to bundle it
        # but let's focus on absolute paths first
        if lib_path.starts_with?("/")
          lib_name = File.basename(lib_path)
          dest_path = File.join(frameworks_dir, lib_name)

          puts "  Copying #{lib_name}..."
          FileUtils.cp(lib_path, dest_path)
          File.chmod(dest_path, 0o755)

          # Update the binary to point to @rpath instead of absolute path
          system("install_name_tool -change #{lib_path} @rpath/#{lib_name} #{binary_path}")

          # Also check if the library itself has absolute dependencies (rare for SDL3 but possible)
          # We'd need to recursive if so, but for now let's keep it simple.
        elsif lib_path.starts_with?("@rpath/")
          # It's already an @rpath, but is the library in the bundle?
          lib_name = lib_path.gsub("@rpath/", "")

          # Try to find where it is on the system to copy it
          # Common places: /usr/local/lib, /opt/homebrew/lib
          search_paths = ["/usr/local/lib", "/opt/homebrew/lib", "/usr/local/opt/sdl3/lib", "/opt/homebrew/opt/sdl3/lib"]
          found = false
          search_paths.each do |sp|
            full_sp = File.join(sp, lib_name)
            if File.exists?(full_sp)
              puts "  Copying #{lib_name} (found in #{sp})..."
              FileUtils.cp(full_sp, File.join(frameworks_dir, lib_name))
              File.chmod(File.join(frameworks_dir, lib_name), 0o755)
              found = true
              break
            end
          end
          puts "  Warning: Could not find source for #{lib_name} to bundle." unless found
        end
      end
    end

    private def package_win
      puts "Packaging for Windows..."
      release_name = "#{@app_name.gsub(' ', '-')}-win-#{@arch}-v#{@version}"
      package_dir = File.join(@output_dir, release_name)
      FileUtils.mkdir_p(package_dir)

      # Copy binary (on Windows it would have .exe)
      # Assuming we are on Windows or have the .exe
      bin_src = File.join(@build_dir, "#{@game}.exe")

      if File.exists?(bin_src)
        FileUtils.cp(bin_src, File.join(package_dir, "#{@app_name}.exe"))
      else
        puts "Warning: Binary #{bin_src} not found. Skipping binary copy."
      end

      # Copy assets.pack
      FileUtils.cp(@assets_pack, File.join(package_dir, "assets.pack"))

      # Copy all DLLs from build directory
      puts "Bundling DLLs..."
      # Normalize build_dir path to use forward slashes for Dir.glob
      normalized_build_dir = @build_dir.gsub('\\', '/')
      glob_pattern = File.join(normalized_build_dir, "*.dll")

      found_dlls = Dir.glob(glob_pattern)

      # Fallback if glob fails to find anything
      if found_dlls.empty?
        if Dir.exists?(normalized_build_dir)
          Dir.children(normalized_build_dir).each do |filename|
            if filename.downcase.ends_with?(".dll")
              found_dlls << File.join(normalized_build_dir, filename)
            end
          end
        end
      end

      found_dlls.each do |dll_path|
        dll_name = File.basename(dll_path)
        puts "  Copying #{dll_name}..."
        FileUtils.cp(dll_path, File.join(package_dir, dll_name))
      end

      # Zip it
      puts "Creating zip archive..."
      has_zip = false
      begin
        # Use a simpler check that won't throw if missing on Windows
        {% if flag?(:win32) %}
          has_zip = system("where zip > NUL 2>&1")
        {% else %}
          has_zip = system("command -v zip > /dev/null 2>&1")
        {% end %}
      rescue
        has_zip = false
      end

      if has_zip
        system("cd #{@output_dir} && zip -rj #{release_name}.zip #{release_name}/*")
      else
        puts "  'zip' command not found, falling back to PowerShell Compress-Archive..."
        # Change into the output directory to avoid nested folders
        abs_output_dir = File.expand_path(@output_dir)
        dest_zip = "#{release_name}.zip"

        # PowerShell command: Compress-Archive -Path 'source' -DestinationPath 'dest' -Force
        # We run this from WITHIN the output directory and use /* to zip contents only
        ps_cmd = "powershell -Command \"Set-Location '#{abs_output_dir}'; Compress-Archive -Path '#{release_name}/*' -DestinationPath '#{dest_zip}' -Force\""
        system(ps_cmd) || puts "  Warning: Failed to create zip via PowerShell. Please zip #{File.join(@output_dir, release_name)} manually."
      end
    end

    private def package_linux
      puts "Packaging for Linux..."
      release_name = "#{@app_name.gsub(' ', '-')}-linux-#{@arch}-v#{@version}"
      package_dir = File.join(@output_dir, release_name)
      FileUtils.mkdir_p(package_dir)

      # Copy binary
      binary_dest = File.join(package_dir, @app_name.gsub(' ', '-'))
      FileUtils.cp(File.join(@build_dir, @game), binary_dest)
      File.chmod(binary_dest, 0o755)

      # Copy assets.pack
      FileUtils.cp(@assets_pack, File.join(package_dir, "assets.pack"))

      # Find and copy libraries (SDL3 etc.)
      puts "Bundling dynamic libraries for Linux..."
      # Use ldd to find dependencies
      output = `ldd #{binary_dest}`
      output.each_line do |line|
        line = line.strip
        # Format: libSDL3.so.0 => /usr/local/lib/libSDL3.so.0 (0x0000...)
        if line.includes?("=>")
          parts = line.split("=>")
          lib_name = parts[0].strip
          lib_data = parts[1].split("(")[0].strip

          # Only bundle libraries we are interested in (SDL3 etc)
          if lib_name.downcase.includes?("sdl3")
            if !lib_data.empty? && File.exists?(lib_data)
              puts "  Copying #{lib_name}..."
              # Use cp -L to follow symlinks and copy the actual file content
              system("cp -L #{lib_data} #{File.join(package_dir, lib_name)}")
            else
              puts "  Warning: Could not find library source for #{lib_name} (path: '#{lib_data}')"
            end
          end
        end
      end

      # Tar it
      puts "Creating tar.gz archive..."
      system("cd #{@output_dir} && tar -czf #{release_name}.tar.gz #{release_name}")
    end
  end
end

GSDL::ReleaseHelper.new.run
