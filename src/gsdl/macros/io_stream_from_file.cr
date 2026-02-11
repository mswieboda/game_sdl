require "sdl3"

filepath = ARGV[0]
SDL3::IOStream.from_file(filepath, "rb")
