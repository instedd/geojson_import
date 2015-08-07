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
      if not_first_iteration && (lng < @min_lng && (@min_lng - lng) > 180)
        lng = lng + 360
      end
      if not_first_iteration && (lng > @max_lng && (@max_lng - lng) < -180)
        lng = lng - 360
      end
      @min_lat = lat if lat < @min_lat
      @max_lat = lat if lat > @max_lat
      @min_lng = lng if lng < @min_lng
      @max_lng = lng if lng > @max_lng
    end

    def not_first_iteration
      @min_lng != 180 && @max_lng != -180
    end

    def center
      lng = (@min_lng + @max_lng) / 2
      lng = lng - 360 if lng > 180
      lng = lng + 360 if lng < -180
      [lng, (@min_lat + @max_lat) / 2]
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
