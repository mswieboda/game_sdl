module GSDL
  class SceneManager
    getter scene : Scene
    # getter keys
    # getter mouse
    # getter joysticks
    getter? exit

    def initialize
      # @keys = Keys.new
      # @mouse = Mouse.new
      # @joysticks = Joysticks.new
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

    def update(frame_time : Float32)
      check_scenes
      scene.update(frame_time) #, keys, mouse, joysticks)
      # keys.reset
      # mouse.reset
      # joysticks.reset
    end

    def draw(renderer : SDL3::Renderer)
      scene.draw(renderer)
    end
  end
end
