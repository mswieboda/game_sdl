require "../src/game_sdl"

# Test script for Binary Persistence
path = "save_test.bin"

# 1. Set some data
GSDL::Data.set(["player", "name"], "Hero")
GSDL::Data.set(["player", "health"], 100)
GSDL::Data.set("level", 5)

puts "Saving data to #{path}..."
GSDL::Data.save(path)

# 2. Clear and Reload
puts "Clearing data and reloading..."
GSDL::Data.clear
GSDL::Data.load(path)

# 3. Verify
name = GSDL::Data.get("player")["name"].as_s
health = GSDL::Data.get("player")["health"].as_i
level = GSDL::Data.get("level").as_i

puts "Loaded Name: #{name}"
puts "Loaded Health: #{health}"
puts "Loaded Level: #{level}"

if name == "Hero" && health == 100 && level == 5
  puts "SUCCESS: Binary persistence working correctly."
else
  puts "FAILURE: Data mismatch."
  exit 1
end

# 4. Check that it's binary
File.open(path, "rb") do |f|
  magic = f.read_string(4)
  puts "Magic Number: #{magic}"
  if magic != "GSDL"
    puts "FAILURE: File is not in binary format."
    exit 1
  end
end

File.delete(path)
puts "Cleanup: #{path} deleted."
