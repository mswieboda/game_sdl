require "sdl3"
require "file" # Added to ensure File.read_bytes is available in macros

require "./gsdl/core/*"
require "./gsdl/audio/*"
require "./gsdl/gfx/*"
require "./gsdl/ui/*"
require "./gsdl/input/*"

module GSDL
  alias Color = SDL3::Color
  alias FColor = SDL3::FColor
  alias FPoint = SDL3::FPoint
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect
  alias Renderer = SDL3::Renderer

  # TODO: maybe move this somewhere else
  macro embed_io_stream(filename)
    SDL3::IOStream.from_file({{filename}}, "rb")
  end
end
