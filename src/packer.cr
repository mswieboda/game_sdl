require "option_parser"

# This script scans an asset directory and packages all files into a single
# binary .pack file. This can be used as a library or a command-line tool.
module GSDL
  class Packer
    # Format of the packfile created by this tool
    # GSDL checks this to make sure it is indeed a packfile created from GSDL
    FormatCode = "PACK"

    # Represents a single asset to be included in the packfile.
    private class Entry
      property path : String   # Relative path, e.g., "gfx/ship.png"
      property full_path : String # Full path on disk for reading
      property size : UInt64
      property! offset : UInt64

      def initialize(@path, @full_path)
        @size = File.size(@full_path).to_u64
        @offset = 0_u64 # Will be calculated later
      end
    end

    @input_dir : String
    @output_file : String

    def initialize(@input_dir, @output_file)
    end

    # Executes the packing process.
    def run
      puts "Packing assets from '#{@input_dir}' into '#{@output_file}'..."

      # 1. Discover all asset files
      assets_root = Path[@input_dir]
      all_files = Dir.glob("#{assets_root}/**/*").select { |f| File.file?(f) }

      unless all_files.any?
        puts "No files found in #{@input_dir}. Nothing to pack."
        return
      end

      entries = all_files.map do |full_path|
        relative_path = Path[full_path].relative_to(assets_root).to_posix.to_s
        Entry.new(relative_path, full_path)
      end

      puts "Found #{entries.size} assets to pack."

      # 2. Calculate offsets and total manifest size
      manifest_header_size = 4 + 4 # Magic number + entry count
      manifest_body_size = entries.sum do |entry|
        4 + entry.path.bytesize + 8 + 8 # path_len + path + offset + size
      end
      manifest_total_size = manifest_header_size + manifest_body_size

      current_data_offset = manifest_total_size.to_u64
      entries.each do |entry|
        entry.offset = current_data_offset
        current_data_offset += entry.size
      end

      # 3. Write the packfile
      output_dir = File.dirname(@output_file)
      Dir.mkdir_p(output_dir) unless Dir.exists?(output_dir)

      File.open(@output_file, "w") do |file|
        file.write FormatCode.to_slice
        file.write_bytes(entries.size.to_u32, IO::ByteFormat::LittleEndian)

        entries.each do |entry|
          file.write_bytes(entry.path.bytesize.to_u32, IO::ByteFormat::LittleEndian)
          file.write entry.path.to_slice
          file.write_bytes(entry.offset, IO::ByteFormat::LittleEndian)
          file.write_bytes(entry.size, IO::ByteFormat::LittleEndian)
        end

        entries.each do |entry|
          File.open(entry.full_path, "r") do |asset_file|
            IO.copy(asset_file, file)
          end
        end
      end

      total_size_kb = File.size(@output_file) / 1024.0
      puts "Successfully created asset pack at #{@output_file}"
      puts "Total size: %.2f KB" % total_size_kb
    end
  end
end

# --- Command-Line Execution ---

# Default paths for simple `make pack` execution
input_dir = "assets"
output_file = "build/assets.pack"

OptionParser.parse do |parser|
  parser.banner = "GSDL Asset Packer. Usage: crystal src/pack.cr [arguments]"
  parser.on("-i DIR", "--input=DIR", "Input assets directory (default: 'assets')") { |dir| input_dir = dir }
  parser.on("-o FILE", "--output=FILE", "Output packfile path (default: 'build/assets.pack')") { |file| output_file = file }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end

# Create and run the packer with the specified or default options
packer = GSDL::Packer.new(input_dir, output_file)
packer.run
