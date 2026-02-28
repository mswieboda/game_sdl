require "sdl3"

require "./gsdl/asset_manager"
require "./gsdl/core/*"
require "./gsdl/audio/*"
require "./gsdl/physics/*"
require "./gsdl/gfx/*"
require "./gsdl/gfx/geo/*"
require "./gsdl/ui/font"
require "./gsdl/ui/font_manager"
require "./gsdl/ui/text_engine"
require "./gsdl/ui/text_base"
require "./gsdl/ui/text"
require "./gsdl/ui/text_box"
require "./gsdl/ui/text_rotated"
require "./gsdl/ui/text_typed"
require "./gsdl/ui/message"
require "./gsdl/ui/message_typed"
require "./gsdl/ui/button"
require "./gsdl/ui/menu"
require "./gsdl/ui/dialog_manager"
require "./gsdl/ui/dialog_box"
require "./gsdl/input/*"

module GSDL
  alias Num = Int32 | Float32
end
