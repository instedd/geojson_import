module Geojson

  class FeatureCollection

    def initialize(hash)
      @data = hash
    end

    def self.from_path(path)
      data = JSON.load(File.open(path))
      self.new(data)
    end

    def features
      @data["features"].each do |feature_data|
        properties = feature_data["properties"]

        iso = properties["ISO"]
        name0 = properties["NAME_0"] || properties["NAME_ENGLI"]
        name1 = properties["NAME_1"]
        name2 = properties["NAME_2"]
        name3 = properties["NAME_3"]
        name4 = properties["NAME_4"]

        id0 = properties["ID_0"]
        id1 = properties["ID_1"]
        id2 = properties["ID_2"]
        id3 = properties["ID_3"]
        id4 = properties["ID_4"]
        iso = properties["ISO"]

        feature = Feature.new
        geometry = feature_data["geometry"]
        feature.type = geometry["type"].downcase
        feature.coordinates = geometry["coordinates"]

        if id4
          feature.name = name4
          feature.location_id = "#{id0}_#{id1}_#{id2}_#{id3}_#{id4}"
          feature.parent_id = "#{id0}_#{id1}_#{id2}_#{id3}"
          feature.level = 4
        elsif id3
          feature.name = name3
          feature.location_id = "#{id0}_#{id1}_#{id2}_#{id3}"
          feature.parent_id = "#{id0}_#{id1}_#{id2}"
          feature.level = 3
        elsif id2
          feature.name = name2
          feature.location_id = "#{id0}_#{id1}_#{id2}"
          feature.parent_id = "#{id0}_#{id1}"
          feature.level = 2
        elsif id1
          feature.name = name1
          feature.location_id = "#{id0}_#{id1}"
          feature.parent_id = id0
          feature.level = 1
        else
          feature.name = name0
          feature.location_id = id0
          feature.level = 0
        end

        feature.center = PointCollector.compute_center(feature.coordinates)

        yield feature

      end

    end

  end

end
