module Geojson

  class PointCollector
    def initialize
      @points = []
    end

    def <<(point)
      @points.push point
    end

    # Based on https://en.wikipedia.org/wiki/Centroid#Centroid_of_polygon
    # See http://stackoverflow.com/questions/22796520/finding-the-center-of-leaflet-polygon
    def center
      two_times_signed_area = 0
      cx_times_6_signed_area = 0
      cy_times_6_signedArea = 0

      length = @points.length

      (0...@points.length).each do |i|
        two_sa = modulus_x(i) * modulus_y(i + 1) - modulus_x(i + 1) * modulus_y(i)
        two_times_signed_area += two_sa
        cx_times_6_signed_area += (modulus_x(i) + modulus_x(i + 1)) * two_sa
        cy_times_6_signedArea += (modulus_y(i) + modulus_y(i + 1)) * two_sa
      end

      six_signed_area = 3 * two_times_signed_area
      [cx_times_6_signed_area / six_signed_area, cy_times_6_signedArea / six_signed_area]       
    end

    def self.compute_center(coords)
      collector = PointCollector.new
      computer_center_with_collector collector, coords
      collector.center
    end

    def self.computer_center_with_collector(collector, coords)
      if coords.length <= 3 && coords.all? { |c| c.is_a?(Numeric) }
        collector << coords
      else
        coords.each do |coord|
          computer_center_with_collector collector, coord
        end
      end
    end

    private
    
    def modulus_x(i)
      @points[i % @points.length][0]
    end

    def modulus_y(i)
      @points[i % @points.length][1]
    end
  end
end
