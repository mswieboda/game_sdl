require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Particle System Ex", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = ParticleScene.new
    end
  end

  class ParticleScene < GSDL::Scene
    @emitters : Array(GSDL::ParticleEmitter)
    @text : GSDL::Text

    def initialize
      super(:particle)
      @emitters = [] of GSDL::ParticleEmitter

      # Fire-like emitter
      fire = GSDL::ParticleEmitter.new(max_particles: 200)
      fire.x = 200
      fire.y = 500
      fire.rate = 50
      fire.speed_range = 50.0_f32..100.0_f32
      fire.angle_range = 250.0_f32..290.0_f32
      fire.lifetime_range = 0.5_f32..1.5_f32
      fire.size_range = 10.0_f32..20.0_f32
      fire.end_size_range = 2.0_f32..5.0_f32
      fire.color_range = {GSDL::Color::Red, GSDL::Color::Orange}
      fire.end_color_range = {GSDL::Color.new(r: 50, g: 50, b: 50, a: 0), GSDL::Color.new(r: 100, g: 100, b: 100, a: 0)}
      fire.shape = GSDL::Collidable::Shape::Rect
      @emitters << fire

      # Fountain-like emitter
      fountain = GSDL::ParticleEmitter.new(max_particles: 500)
      fountain.x = 400
      fountain.y = 300
      fountain.rate = 100
      fountain.gravity = GSDL::Point.new(0, 300)
      fountain.speed_range = 200.0_f32..400.0_f32
      fountain.angle_range = 240.0_f32..300.0_f32
      fountain.lifetime_range = 2.0_f32..3.0_f32
      fountain.size_range = 2.0_f32..4.0_f32
      fountain.color_range = {GSDL::Color::Cyan, GSDL::Color::Blue}
      fountain.end_color_range = {GSDL::Color.new(r: 0, g: 0, b: 255, a: 0), GSDL::Color.new(r: 0, g: 0, b: 255, a: 0)}
      fountain.shape = GSDL::Collidable::Shape::Circle
      @emitters << fountain

      # Burst emitter (Mouse click)
      @burst_emitter = GSDL::ParticleEmitter.new(max_particles: 1000)
      @burst_emitter.speed_range = 100.0_f32..300.0_f32
      @burst_emitter.lifetime_range = 0.5_f32..1.0_f32
      @burst_emitter.size_range = 3.0_f32..8.0_f32
      @burst_emitter.color_range = {GSDL::Color::White, GSDL::Color::Yellow}
      @burst_emitter.end_color_range = {GSDL::Color.new(r: 255, g: 255, b: 0, a: 0), GSDL::Color.new(r: 255, g: 255, b: 0, a: 0)}
      @burst_emitter.shape = GSDL::Collidable::Shape::Rect
      @emitters << @burst_emitter

      @text = GSDL::Text.new(
        text: "Click to Burst! SPACE to reset.",
        color: GSDL::Color::White
      )
      @text.x = 20
      @text.y = 20
    end

    def update(dt : Float32)
      if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
        @burst_emitter.x = GSDL::Mouse.x.to_f32
        @burst_emitter.y = GSDL::Mouse.y.to_f32
        @burst_emitter.burst(50)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @emitters.each &.reset
      end

      @emitters.each &.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @emitters.each &.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
