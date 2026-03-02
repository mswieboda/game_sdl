module GSDL
  class SceneManager
    getter scene : Scene
    getter? exit

    def initialize
      @scene = Scene.new
      @exit = false
    end

    private def update_transitions(dt : Float32)
      if scene.transition_in.running?
        scene.transition_in.update(dt)

        scene.transition_in.clear if scene.transition_in.done?

        return
      end

      if scene.transition_out.running?
        scene.transition_out.update(dt)

        if scene.transition_out.done?
          scene.transition_out.clear
          scene.exit
        end
      end
    end

    # check when to switch scenes using `switch(scene : Scene)`
    protected def check_scenes
    end

    # called within check_scenes in child classes
    protected def switch(scene : Scene)
      @scene.reset
      @scene = scene
      @scene.init
    end

    def switch_async(scene_class : T.class) forall T
      loader = Game.instance.loader
      tasks = T.manifest
      
      if tasks.empty?
        switch(T.new)
      else
        loader.add_tasks(tasks)
        loader.start_async
        switch(T.loading_scene_class(scene_class))
      end
    end

    def update(dt : Float32)
      update_transitions(dt)

      if scene.transition_in.started? || scene.transition_out.started?
        return
      end

      check_scenes
      scene.update(dt)
    end

    def draw(draw : Draw)
      scene.draw(draw) unless exit?
      scene.transition_in.draw(draw) if scene.transition_in.running?
      scene.transition_out.draw(draw) if scene.transition_out.started?
    end
  end
end
