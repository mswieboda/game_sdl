module GSDL
  class SceneManager
    getter scene : Scene
    getter? exit

    def initialize
      @scene = Scene.new
      @exit = false
    end

    # check when to switch scenes using `switch(scene : Scene)`
    def check_scenes
    end

    def switch(scene : Scene)
      @scene.reset
      @scene = scene
      @scene.init
    end

    def update(dt : Float32)
      check_scenes
      scene.update(dt)
    end

    def draw(renderer : SDL3::Renderer)
      scene.draw(renderer)
    end
  end
end
