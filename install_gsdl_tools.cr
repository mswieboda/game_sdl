# This script helps users install the GSDL packer tool into their
# project's local `bin` directory after `shards install`.
#
# To use, a consumer project should run:
# crystal lib/game_sdl/install_gsdl_tools.cr

require "file_utils"

puts "GSDL: Installing packer tool to local ./bin/ directory..."

# Determine the current directory of this script (lib/game_sdl)
script_dir = __DIR__

make packer

# Path to the pre-compiled gsdl-packer within the installed shard
{% if flag?(:windows) %}
  packer_source_path = File.join(script_dir, "bin/gsdl-packer.exe")
{% else %}
  packer_source_path = File.join(script_dir, "bin/gsdl-packer")
{% end %}

# The target `bin` directory in the consumer's project root
# We go up two levels from script_dir (lib/game_sdl -> lib -> project_root)
project_root = File.expand_path(File.join(script_dir, "..", ".."))
target_bin_dir = File.join(project_root, "bin")
target_packer_path = File.join(target_bin_dir, "gsdl-packer")

unless File.exists?(packer_source_path)
  puts "GSDL: ERROR - Pre-compiled packer tool not found at '#{packer_source_path}'."
  puts "GSDL: Please ensure you've run 'make build-packer' in the game_sdl project."
  exit 1
end

# Ensure the target ./bin directory exists
Dir.mkdir_p(target_bin_dir)

# Copy the binary and make it executable
begin
  FileUtils.cp(packer_source_path, target_packer_path)
  File.chmod(target_packer_path, 0o755)
  puts "GSDL: Packer tool successfully installed at '#{target_packer_path}'"
  puts "GSDL: You can now run it with: ./bin/gsdl-packer --help"
rescue ex
  puts "GSDL: ERROR - Failed to copy packer tool: #{ex.message}"
  exit 1
end
