require "sdl3"

require "./gsdl/core/*"
require "./gsdl/gfx/*"
require "./gsdl/input/*"
require "./gsdl/ui/*"

module GSDL
  alias FPoint = SDL3::FPoint
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect
  alias Renderer = SDL3::Renderer
end
