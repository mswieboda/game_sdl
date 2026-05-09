require "../src/game_sdl"

class ScaleTest < GSDL::Game
  def init
    puts "Display scale: #{ScaleTest.draw.content_scale}"
  end
end

ScaleTest.new(title: "Scale Test", high_pixel_density: true).run
