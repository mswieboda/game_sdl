module GSDL
  abstract class Shape
    include Tweenable
    include Centerable

    alias ScaleType = Tuple(Num, Num)

    enum DrawMode
      Fill
      Outline
      Border
    end

    # for creating getter/setter, for variables affecting update_geometry
    # so we know to call update_geometry in draw methods, if this var changes
    # ex:
    # alias Vertices = Array(Vertex)
    # getters_update_geometry({fill_vertices : Vertices = [] of Vertex})
    #
    # outputs to:
    # @fill_vertices : Vertices = [] of Vertex
    # def fill_vertices : Vertices
    #   update_geometry if @changed
    #   @fill_vertices
    # end
    macro properties_changed(properties)
      {% for name, type_info in properties %}
        # Handle both simple type (Float32) and type with default (Float32 = 0.0)
        {% if type_info.is_a?(Assign) %}
          {% type = type_info.target %}
          {% default = type_info.value %}
        {% else %}
          {% type = type_info %}
          {% default = nil %}
        {% end %}

        getter {{name.id}} : {{type}}{{ (default != nil ? " = #{default}".id : "".id) }}

        def {{name.id}}=(value : {{type}})
          return if @{{name.id}} == value
          @{{name.id}} = value
          @changed = true
        end
      {% end %}
    end

    # for getters, with variables calculated inside update_geometry so the variable is updated first
    # ex:
    # alias Vertices = Array(Vertex)
    # getters_update_geometry({fill_vertices : Vertices = [] of Vertex})
    #
    # outputs to:
    # @fill_vertices : Vertices = [] of Vertex
    # def fill_vertices : Vertices
    #   update_geometry if @changed
    #   @fill_vertices
    # end
    macro getters_update_geometry(properties)
      {% for name, type_info in properties %}
        {% if type_info.is_a?(Assign) %}
          {% type = type_info.target %}
          {% default = type_info.value %}
        {% else %}
          {% type = type_info %}
          {% default = nil %}
        {% end %}

        @{{name.id}} : {{type}}{{ (default != nil ? " = #{default}".id : "".id) }}

        def {{name.id}} : {{type}}
          update_geometry if @changed
          @{{name.id}}
        end
      {% end %}
    end

    properties_changed({
      x: Num = 0,
      y: Num = 0,
      scale: ScaleType = {1_f32, 1_f32},
      rotation: Num = 0,
      color: Color = Color::White,
      draw_mode: DrawMode = DrawMode::Fill,
      border_thickness: Num = 1,
      border_color: Color = Color::White
    })

    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    getter? changed : Bool = true
    property z_index : Int32 = 0

    getter tweens : Array(Tween) = [] of Tween

    def initialize(
      @x : Num = 0,
      @y : Num = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @rotation : Num = 0,
      @color : Color = Color::White,
      @z_index : Int32 = 0,
      @draw_mode : DrawMode = DrawMode::Fill,
      @border_thickness : Num = 1,
      @border_color : Color = Color::White
    )
    end

    def rotation_radians : Float64
      rotation.to_f64 * (Math::PI / 180.0)
    end

    def rotate_point(px : Num, py : Num) : Tuple(Float32, Float32)
      return {px.to_f32, py.to_f32} if rotation == 0

      # Rotation around the logical (x, y) point (our pivot)
      cx = x.to_f32
      cy = y.to_f32

      rad = rotation_radians
      cos_a = Math.cos(rad)
      sin_a = Math.sin(rad)

      dx = px.to_f32 - cx
      dy = py.to_f32 - cy

      nx = cx + dx * cos_a - dy * sin_a
      ny = cy + dx * sin_a + dy * cos_a

      {nx.to_f32, ny.to_f32}
    end

    def scale=(val : Tuple(Num, Num))
      return if @scale == val
      @scale = val
      @changed = true
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(val : Num)
      self.scale = {val, scale_y}
    end

    def scale_y=(val : Num)
      self.scale = {scale_x, val}
    end

    abstract def width : Num
    abstract def height : Num

    def draw_width : Num
      width * scale_x
    end

    def draw_height : Num
      height * scale_y
    end

    # needs to be called at the end of initialization,
    # and in every #draw method (only if #changed?)
    abstract def update_geometry

    def changed!
      @changed = true
    end

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def draw_x : Num
      x - (draw_width * origin_x)
    end

    def draw_y : Num
      y - (draw_height * origin_y)
    end

    def update(dt : Float32)
      update_tweens(dt)
    end

    def draw(draw : Draw)
      draw_fill(draw) if draw_mode.fill? || draw_mode.border?

      if draw_mode.border?
        draw_border(draw)
      elsif draw_mode.outline?
        draw_outline(draw)
      end
    end

    private def draw_fill(draw : Draw)
      draw(draw)
    end

    private def draw_outline(draw : Draw)
    end

    private def draw_border(draw : Draw)
    end
  end
end
