module Geojson

  class PointChecker

    def initialize

    end

    def contains_point?(point)
      contains_point = false
      i = -1
      j = self.size - 1
      while (i += 1) < self.size
        a_point_on_polygon = self[i]
        trailing_point_on_polygon = self[j]
        if point_is_between_the_ys_of_the_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
          if ray_crosses_through_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
            contains_point = !contains_point
          end
        end
        j = i
      end
      return contains_point
    end

    private

    def point_is_between_the_ys_of_the_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
      (a_point_on_polygon.y <= point.y && point.y < trailing_point_on_polygon.y) ||
      (trailing_point_on_polygon.y <= point.y && point.y < a_point_on_polygon.y)
    end

    def ray_crosses_through_line_segment?(point, a_point_on_polygon, trailing_point_on_polygon)
      (point.x < (trailing_point_on_polygon.x - a_point_on_polygon.x) * (point.y - a_point_on_polygon.y) /
                 (trailing_point_on_polygon.y - a_point_on_polygon.y) + a_point_on_polygon.x)
    end

  end

end
