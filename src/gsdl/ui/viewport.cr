require "./canvas"

module GSDL
  module UI
    class Viewport < Canvas
      property pan_x : Float32 = 0_f32
      property pan_y : Float32 = 0_f32
      property min_zoom : Float32 = 0.1_f32
      property max_zoom : Float32 = 10.0_f32

      getter zoom : Float32 = 1.0_f32

      def initialize(
        width : Int32 = FillParent,
        height : Int32 = FillParent,
        x : Int32 = 0,
        y : Int32 = 0,
        anchor : Anchor = Anchor::Center,
        background_color : Color = Color::Transparent,
        padding = 0,
        margin = 0,
        flex : UInt8 = 1_u8,
      )
        super(
          width: width,
          height: height,
          x: x,
          y: y,
          anchor: anchor,
          background_color: background_color,
          padding: padding,
          margin: margin,
          flex: flex
        )
        self.clips_children = false
      end

      def zoom=(val : Float32)
        @zoom = val.clamp(@min_zoom, @max_zoom)
      end

      # Helper to zoom centering on a specific screen coordinate.
      # If coordinate is nil, defaults to the center of the viewport on screen.
      def zoom_to(new_zoom : Float32, screen_cx : Num? = nil, screen_cy : Num? = nil)
        target_zoom = new_zoom.clamp(@min_zoom, @max_zoom)
        return if @zoom == target_zoom

        cx = screen_cx ? screen_cx.to_f32 : (content_x.to_f32 + width / 2_f32)
        cy = screen_cy ? screen_cy.to_f32 : (content_y.to_f32 + height / 2_f32)

        # Relative to viewport top-left
        rx = cx - content_x
        ry = cy - content_y

        old_zoom = @zoom

        # Formula: new_pan_x = pan_x - rx * (1 / old_zoom - 1 / target_zoom)
        @pan_x -= rx * (1.0_f32 / old_zoom - 1.0_f32 / target_zoom)
        @pan_y -= ry * (1.0_f32 / old_zoom - 1.0_f32 / target_zoom)
        @zoom = target_zoom
      end

      def draw(draw : Draw)
        return unless visible?
        layout! if @dirty_layout

        draw_background(draw)

        # 1. Handle child clipping if enabled
        if clips_children?
          draw.push_clip(GSDL::Rect.new(content_x, content_y, content_width, content_height))
        end

        # 2. Draw children normally (they will query their virtualized coordinates on-the-fly)
        @children.each do |child|
          child.draw(draw) if child.visible?
        end

        if clips_children?
          draw.pop_clip
        end
      end
    end
  end
end
