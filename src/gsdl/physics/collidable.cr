module GSDL
  module Collidable
    enum Shape
      Rect
      Circle
      Polygon
    end

    # requires
    abstract def draw_x : Num
    abstract def draw_y : Num

    # collision bounding box of the collidable object as an FRect
    abstract def collision_bounding_box : FRect

    def collision_shape : Shape
      Shape::Rect
    end

    # For polygons, return the absolute coordinates of the vertices
    def collision_polygon_vertices : Points
      # Default for Rect:
      box = collision_box
      [
        Point.new(box.x, box.y),
        Point.new(box.right, box.y),
        Point.new(box.right, box.bottom),
        Point.new(box.left, box.bottom)
      ]
    end

    # For circles, this would be the radius
    def collision_radius : Float32
      collision_bounding_box.w / 2.0_f32
    end

    def collision_center : Point
      if collision_shape.polygon?
        vs = collision_polygon_vertices
        return Point.new(0, 0) if vs.empty?
        sum_x = vs.sum(&.x)
        sum_y = vs.sum(&.y)
        return Point.new(sum_x / vs.size, sum_y / vs.size)
      end

      box = collision_box
      Point.new(box.x + box.w / 2.0_f32, box.y + box.h / 2.0_f32)
    end

    def collision_box : FRect
      FRect.new(
        x: draw_x + collision_bounding_box.x,
        y: draw_y + collision_bounding_box.y,
        w: collision_bounding_box.w,
        h: collision_bounding_box.h
      )
    end

    def collides?(other : Collidable) : Bool
      # If both are Rects, use fast AABB check
      if collision_shape.rect? && other.collision_shape.rect?
        return collision_box.overlaps?(other.collision_box)
      end

      # If both are Circles
      if collision_shape.circle? && other.collision_shape.circle?
        dist = collision_center.distance(other.collision_center)
        return dist < (collision_radius + other.collision_radius)
      end

      # Circle vs Rect
      if (collision_shape.circle? && other.collision_shape.rect?) || (collision_shape.rect? && other.collision_shape.circle?)
        circle = collision_shape.circle? ? self : other
        rect = collision_shape.rect? ? self : other
        return circle_collides_with_rect?(circle, rect)
      end

      # Polygon vs anything (or Circle vs Rect if we want to treat it as polygon)
      if collision_shape.polygon? || other.collision_shape.polygon?
        # Use SAT
        return sat_collision?(self, other)
      end

      false
    end

    private def sat_collision?(a : Collidable, b : Collidable) : Bool
      # Circle vs Polygon needs special SAT or closest point check
      if a.collision_shape.circle? || b.collision_shape.circle?
        circle = a.collision_shape.circle? ? a : b
        poly = a.collision_shape.circle? ? b : a
        return circle_collides_with_polygon?(circle, poly)
      end

      # Polygon (or Rect) vs Polygon (or Rect)
      poly_a = a.collision_polygon_vertices
      poly_b = b.collision_polygon_vertices

      # Check axes of poly_a
      return false unless sat_check_axes(poly_a, poly_b)
      # Check axes of poly_b
      return false unless sat_check_axes(poly_b, poly_a)

      true
    end

    private def sat_check_axes(poly_a : Points, poly_b : Points) : Bool
      poly_a.each_with_index do |p1, i|
        p2 = poly_a[(i + 1) % poly_a.size]
        edge = p2 - p1
        # Normal to edge
        axis = Point.new(-edge.y, edge.x).normalize

        min_a, max_a = project_polygon(poly_a, axis)
        min_b, max_b = project_polygon(poly_b, axis)

        # Gap found?
        if max_a < min_b || max_b < min_a
          return false
        end
      end
      true
    end

    private def project_polygon(poly : Points, axis : Point) : Tuple(Float32, Float32)
      min = poly.first.dot(axis)
      max = min
      poly.each do |p|
        proj = p.dot(axis)
        min = proj if proj < min
        max = proj if proj > max
      end
      {min, max}
    end

    struct CollisionInfo
      property? hit : Bool = false
      property normal : Point = Point.new(0, 0)
      property penetration : Float32 = 0_f32

      def initialize(@hit : Bool = false, @normal : Point = Point.new(0, 0), @penetration : Float32 = 0_f32)
      end
    end

    def collision_info(other : Collidable) : CollisionInfo
      # Handle Circle vs Circle
      if collision_shape.circle? && other.collision_shape.circle?
        diff = collision_center - other.collision_center
        dist = diff.length
        sum_r = collision_radius + other.collision_radius
        if dist < sum_r
          normal = dist > 0 ? diff.normalize : Point.new(0, -1)
          return CollisionInfo.new(hit: true, normal: normal, penetration: sum_r - dist)
        end
        return CollisionInfo.new
      end

      # Handle cases involving Polygons (including Rects as Polygons)
      if collision_shape.polygon? || other.collision_shape.polygon? || (collision_shape.rect? && other.collision_shape.rect?)
        # For Rect vs Rect, we can still use AABB for speed if needed, 
        # but SAT is more general and gives us MTV easily.
        
        # If one is a circle and other is a polygon
        if (collision_shape.circle? && other.collision_shape.polygon?) || (collision_shape.polygon? && other.collision_shape.circle?)
           return circle_polygon_collision_info(self, other)
        end

        return polygon_collision_info(self, other)
      end

      # Fallback to simple check if not implemented
      CollisionInfo.new(hit: collides?(other), normal: collision_normal(other), penetration: 1.0_f32)
    end

    private def polygon_collision_info(a : Collidable, b : Collidable) : CollisionInfo
      poly_a = a.collision_polygon_vertices
      poly_b = b.collision_polygon_vertices

      min_overlap = Float32::MAX
      smallest_axis = Point.new(0, 0)

      # Check axes of both polygons
      [poly_a, poly_b].each do |poly|
        poly.each_with_index do |p1, i|
          p2 = poly[(i + 1) % poly.size]
          edge = p2 - p1
          axis = Point.new(-edge.y, edge.x).normalize

          min_a, max_a = project_polygon(poly_a, axis)
          min_b, max_b = project_polygon(poly_b, axis)

          overlap = Math.min(max_a, max_b) - Math.max(min_a, min_b)
          if overlap < 0
            return CollisionInfo.new # Gap found
          end

          if overlap < min_overlap
            min_overlap = overlap
            smallest_axis = axis
          end
        end
      end

      # Ensure normal points from b to a
      center_a = a.collision_center
      center_b = b.collision_center
      if (center_a - center_b).dot(smallest_axis) < 0
        smallest_axis = smallest_axis * -1.0_f32
      end

      CollisionInfo.new(hit: true, normal: smallest_axis, penetration: min_overlap)
    end

    private def circle_polygon_collision_info(a : Collidable, b : Collidable) : CollisionInfo
      circle = a.collision_shape.circle? ? a : b
      poly = a.collision_shape.circle? ? b : a
      
      vs = poly.collision_polygon_vertices
      c_center = circle.collision_center
      radius = circle.collision_radius

      min_overlap = Float32::MAX
      smallest_axis = Point.new(0, 0)

      # Check axes of polygon
      vs.each_with_index do |p1, i|
        p2 = vs[(i + 1) % vs.size]
        edge = p2 - p1
        axis = Point.new(-edge.y, edge.x).normalize

        min_a, max_a = project_polygon(vs, axis)
        # Project circle
        circle_proj = c_center.dot(axis)
        min_b = circle_proj - radius
        max_b = circle_proj + radius

        overlap = Math.min(max_a, max_b) - Math.max(min_a, min_b)
        if overlap < 0
          return CollisionInfo.new # Gap
        end

        if overlap < min_overlap
          min_overlap = overlap
          smallest_axis = axis
        end
      end

      # Also check axis from closest vertex to circle center
      # (Important for circle vs vertex collisions)
      closest_v = vs.first
      min_dist_sq = Float32::MAX
      vs.each do |v|
        dist_sq = (c_center.x - v.x)**2 + (c_center.y - v.y)**2
        if dist_sq < min_dist_sq
          min_dist_sq = dist_sq
          closest_v = v
        end
      end

      axis = (c_center - closest_v).normalize
      min_a, max_a = project_polygon(vs, axis)
      circle_proj = c_center.dot(axis)
      min_b = circle_proj - radius
      max_b = circle_proj + radius

      overlap = Math.min(max_a, max_b) - Math.max(min_a, min_b)
      if overlap < 0
        return CollisionInfo.new
      end

      if overlap < min_overlap
        min_overlap = overlap
        smallest_axis = axis
      end

      # Ensure normal points from other to self (if self is 'a')
      # Actually let's just make it point from 'poly' to 'circle' for consistency here
      if (c_center - poly.collision_center).dot(smallest_axis) < 0
        smallest_axis = smallest_axis * -1.0_f32
      end
      
      normal = a == circle ? smallest_axis : smallest_axis * -1.0_f32

      CollisionInfo.new(hit: true, normal: normal, penetration: min_overlap)
    end

    private def circle_collides_with_polygon?(circle : Collidable, poly : Collidable) : Bool
      vs = poly.collision_polygon_vertices
      c_center = circle.collision_center
      radius = circle.collision_radius

      # Check poly edges
      vs.each_with_index do |p1, i|
        p2 = vs[(i + 1) % vs.size]
        
        # Closest point on edge to circle center
        edge = p2 - p1
        t = ((c_center.x - p1.x) * edge.x + (c_center.y - p1.y) * edge.y) / edge.length_squared
        t = Math.max(0.0_f32, Math.min(1.0_f32, t))
        closest = p1 + edge * t
        
        dist_sq = (c_center.x - closest.x)**2 + (c_center.y - closest.y)**2
        return true if dist_sq < radius * radius
      end

      # Also check if circle center is inside polygon (winding number or similar)
      # Simple point-in-polygon check
      inside = false
      j = vs.size - 1
      vs.each_with_index do |p_i, i|
        p_j = vs[j]
        if ((p_i.y > c_center.y) != (p_j.y > c_center.y)) &&
           (c_center.x < (p_j.x - p_i.x) * (c_center.y - p_i.y) / (p_j.y - p_i.y) + p_i.x)
          inside = !inside
        end
        j = i
      end
      
      inside
    end

    private def circle_collides_with_rect?(circle : Collidable, rect : Collidable) : Bool
      closest_x, closest_y = closest_point_on_rect(circle, rect)

      c_center = circle.collision_center
      distance_x = c_center.x - closest_x
      distance_y = c_center.y - closest_y

      # If the distance is less than the circle's radius, an intersection occurs
      distance_squared = (distance_x * distance_x) + (distance_y * distance_y)
      distance_squared < (circle.collision_radius * circle.collision_radius)
    end

    private def closest_point_on_rect(circle : Collidable, rect : Collidable) : Tuple(Float32, Float32)
      c_center = circle.collision_center
      r_box = rect.collision_box

      # Find the closest point to the circle within the rectangle
      closest_x = Math.max(r_box.x, Math.min(c_center.x, r_box.right))
      closest_y = Math.max(r_box.y, Math.min(c_center.y, r_box.bottom))

      {closest_x, closest_y}
    end

    def collision_normal(other : Collidable) : Point
      # If both are polygons (or rect treated as poly), we need SAT normal (MTV)
      # For now, let's keep the existing simple normal logic and add circle-poly normal
      
      if collision_shape.circle? && other.collision_shape.polygon?
        # Normal from closest point on poly to circle center
        vs = other.collision_polygon_vertices
        c_center = collision_center
        
        best_dist_sq = Float32::MAX
        best_closest = Point.new(0, 0)
        
        vs.each_with_index do |p1, i|
          p2 = vs[(i + 1) % vs.size]
          edge = p2 - p1
          t = ((c_center.x - p1.x) * edge.x + (c_center.y - p1.y) * edge.y) / edge.length_squared
          t = Math.max(0.0_f32, Math.min(1.0_f32, t))
          closest = p1 + edge * t
          dist_sq = (c_center.x - closest.x)**2 + (c_center.y - closest.y)**2
          if dist_sq < best_dist_sq
            best_dist_sq = dist_sq
            best_closest = closest
          end
        end
        
        nx = c_center.x - best_closest.x
        ny = c_center.y - best_closest.y
        dist = Math.hypot(nx, ny)
        return Point.new(nx / dist, ny / dist)
      end

      if collision_shape.rect? && other.collision_shape.rect?
        # AABB vs AABB normal - based on penetration (simple implementation)
        # for now, let's keep it simple and return the dominant axis
        diff_x = collision_center.x - other.collision_center.x
        diff_y = collision_center.y - other.collision_center.y
        if diff_x.abs > diff_y.abs
          return Point.new(diff_x > 0 ? 1 : -1, 0)
        else
          return Point.new(0, diff_y > 0 ? 1 : -1)
        end
      end

      if collision_shape.circle? && other.collision_shape.circle?
        # Circle vs Circle normal
        diff_x = collision_center.x - other.collision_center.x
        diff_y = collision_center.y - other.collision_center.y
        dist = Math.hypot(diff_x, diff_y)
        return Point.new(diff_x / dist, diff_y / dist)
      end

      # One Circle, one Rect
      circle = collision_shape.circle? ? self : other
      rect = collision_shape.rect? ? self : other

      closest_x, closest_y = closest_point_on_rect(circle, rect)
      c_center = circle.collision_center

      nx = c_center.x - closest_x
      ny = c_center.y - closest_y

      # If the circle's center is exactly at the closest point, the normal is undefined.
      # This happens if the center is inside the rectangle.
      if nx == 0 && ny == 0
        # Normal is from rect center to circle center
        nx = c_center.x - rect.collision_center.x
        ny = c_center.y - rect.collision_center.y
      end

      dist = Math.hypot(nx, ny)
      normal = Point.new(nx / dist, ny / dist)

      # Ensure normal points from other (parameter) towards self
      if circle == self
        normal
      else
        Point.new(-normal.x, -normal.y)
      end
    end
  end
end
