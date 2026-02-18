module GSDL
  abstract class Shape
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
      # TODO: implement these
      # origin_x: Num = 0,
      # origin_y: Num = 0,
      # rotation: Num = 0,
      # scale_x: Num = 0,
      # scale_y: Num = 0,
      color: Color = Color::White,
      draw_mode: DrawMode = DrawMode::Fill,
      border: Num = 0
    })

    getter? changed : Bool = true

    def initialize(
      @x : Num = 0,
      @y : Num = 0,
      @color : Color = Color::White,
      @draw_mode : DrawMode = DrawMode::Fill
    )
    end

    # needs to be called at the end of initialization,
    # and in every #draw method (only if #changed?)
    abstract def update_geometry

    def changed!
      @changed = true
    end

    def draw(draw : Draw)
      if draw_mode.outline?
        draw_outline(draw)
      else
        draw_filled(draw)
        draw_border(draw) if draw_mode.border?
      end
    end

    private def draw_filled(draw : Draw)
      draw(draw)
    end

    private def draw_outline(draw : Draw)
      draw(draw)
    end

    private def draw_border(draw : Draw)
    end
  end
end
