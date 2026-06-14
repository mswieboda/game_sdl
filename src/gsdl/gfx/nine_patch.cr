module GSDL
  class NinePatch
    getter texture : GSDL::Texture
    getter left : Int32
    getter right : Int32
    getter top : Int32
    getter bottom : Int32

    def initialize(@texture : GSDL::Texture, @left : Int32, @right : Int32, @top : Int32, @bottom : Int32)
    end

    def draw(
      draw : GSDL::Draw,
      dest_x : Num,
      dest_y : Num,
      dest_w : Num,
      dest_h : Num,
      z_index : Int32 = 0,
      color : Color = Color::White,
      tint : Color? = nil
    )
      tw = @texture.width
      th = @texture.height

      # Calculate Source Slices (The internal texture bounding grid)
      src_center_w = tw - @left - @right
      src_center_h = th - @top - @bottom

      # Calculate Destination Slices (The actual UI element boundaries on screen)
      dst_center_w = dest_w - @left - @right
      dst_center_h = dest_h - @top - @bottom

      # Phase 1: Render Corners (1:1 static mapping)
      # Top-Left
      draw.texture(
        texture: @texture,
        source_rect: FRect.new(0, 0, @left, @top),
        dest_rect: FRect.new(dest_x, dest_y, @left, @top),
        z_index: z_index,
        color: color,
        tint: tint
      )
      # Top-Right
      draw.texture(
        texture: @texture,
        source_rect: FRect.new(tw - @right, 0, @right, @top),
        dest_rect: FRect.new(dest_x + dest_w - @right, dest_y, @right, @top),
        z_index: z_index,
        color: color,
        tint: tint
      )
      # Bottom-Left
      draw.texture(
        texture: @texture,
        source_rect: FRect.new(0, th - @bottom, @left, @bottom),
        dest_rect: FRect.new(dest_x, dest_y + dest_h - @bottom, @left, @bottom),
        z_index: z_index,
        color: color,
        tint: tint
      )
      # Bottom-Right
      draw.texture(
        texture: @texture,
        source_rect: FRect.new(tw - @right, th - @bottom, @right, @bottom),
        dest_rect: FRect.new(dest_x + dest_w - @right, dest_y + dest_h - @bottom, @right, @bottom),
        z_index: z_index,
        color: color,
        tint: tint
      )

      # Phase 2: Render Linear Edges (Single-axis scaling maps)
      # Top Edge
      if src_center_w > 0 && dst_center_w > 0
        draw.texture(
          texture: @texture,
          source_rect: FRect.new(@left, 0, src_center_w, @top),
          dest_rect: FRect.new(dest_x + @left, dest_y, dst_center_w, @top),
          z_index: z_index,
          color: color,
          tint: tint
        )
      end
      # Bottom Edge
      if src_center_w > 0 && dst_center_w > 0
        draw.texture(
          texture: @texture,
          source_rect: FRect.new(@left, th - @bottom, src_center_w, @bottom),
          dest_rect: FRect.new(dest_x + @left, dest_y + dest_h - @bottom, dst_center_w, @bottom),
          z_index: z_index,
          color: color,
          tint: tint
        )
      end
      # Left Edge
      if src_center_h > 0 && dst_center_h > 0
        draw.texture(
          texture: @texture,
          source_rect: FRect.new(0, @top, @left, src_center_h),
          dest_rect: FRect.new(dest_x, dest_y + @top, @left, dst_center_h),
          z_index: z_index,
          color: color,
          tint: tint
        )
      end
      # Right Edge
      if src_center_h > 0 && dst_center_h > 0
        draw.texture(
          texture: @texture,
          source_rect: FRect.new(tw - @right, @top, @right, src_center_h),
          dest_rect: FRect.new(dest_x + dest_w - @right, dest_y + @top, @right, dst_center_h),
          z_index: z_index,
          color: color,
          tint: tint
        )
      end

      # Phase 3: Render Center Fill (Dual-axis scaling map)
      if src_center_w > 0 && src_center_h > 0 && dst_center_w > 0 && dst_center_h > 0
        draw.texture(
          texture: @texture,
          source_rect: FRect.new(@left, @top, src_center_w, src_center_h),
          dest_rect: FRect.new(dest_x + @left, dest_y + @top, dst_center_w, dst_center_h),
          z_index: z_index,
          color: color,
          tint: tint
        )
      end
    end
  end
end
