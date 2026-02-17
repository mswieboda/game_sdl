require "sdl3"

require "./gsdl/asset_manager"
require "./gsdl/core/*"
require "./gsdl/audio/*"
require "./gsdl/physics/*"
require "./gsdl/gfx/*"
require "./gsdl/ui/*"
require "./gsdl/input/*"

module GSDL
  alias FPoint = SDL3::FPoint
  alias FRect = SDL3::FRect
  alias RectSDL = SDL3::Rect
end
