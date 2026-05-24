require "sdl3"
require "weak_ref"
require "./ext/stb_truetype"

require "./gsdl/asset_manager"
require "./gsdl/core/loadable"
require "./gsdl/core/tweenable"
require "./gsdl/core/saveable"
require "./gsdl/core/entity"
require "./gsdl/core/projection_matrix"
require "./gsdl/core/*"
require "./gsdl/audio/*"
require "./gsdl/physics/physics"
require "./gsdl/physics/body"
require "./gsdl/physics/physics_controller"
require "./gsdl/physics/*"
require "./gsdl/gfx/*"
require "./gsdl/gfx/geo/*"
require "./gsdl/ui/*"
require "./gsdl/input/*"

module GSDL
  alias Num = Int32 | Float32
end
