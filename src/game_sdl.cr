require "sdl3"

require "./gsdl/asset_manager"
require "./gsdl/core/*"
require "./gsdl/audio/*"
require "./gsdl/physics/*"
require "./gsdl/gfx/*"
require "./gsdl/gfx/geo/*"
require "./gsdl/ui/*"
require "./gsdl/input/*"

module GSDL
  alias Num = Int32 | Float32
  alias FPoint = SDL3::FPoint
end
