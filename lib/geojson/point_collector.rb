module Geojson

  class PointCollector
    def initialize
      @min_lat = 90
      @max_lat = -90
      @min_lng = 180
      @max_lng = -180
    end

    def <<(point)
      lng, lat = point
      @min_lat = lat if lat < @min_lat
      @max_lat = lat if lat > @max_lat
      @min_lng = lng if lng < @min_lng
      @max_lng = lng if lng > @max_lng
    end

    def center
      [(@min_lng + @max_lng) / 2, (@min_lat + @max_lat) / 2]
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
  end

end
