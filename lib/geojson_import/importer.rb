module Geojson

  class Importer

    attr_reader :filenames

    def initialize(files)
      @filenames = files
      @created = 0
      @updated = 0
      @failed = 0
    end

    def import!
      Geojson.logger.warn "No files provided for importing." if filenames.blank?
      filenames.sort.map do |filename|
        Geojson.logger.info "Processing file: #{filename}"
        FeatureCollection.from_path(filename).features do |feature|
          import_feature(feature)
        end
      end
      Geojson.logger.warn "\n---\n\nCreated\t#{@created}\nUpdated\t#{@updated}\nFailed\t#{@failed}\nTotal processed\t#{@created+@updated+@failed}"
    end

    def import_feature(feature)
      Geojson.logger.info "  #{feature.name} (id: #{feature.location_id}) at #{feature.center}"
      existing = Location.where(geo_id: feature.location_id).first

      if existing.nil?
        create_location(feature)
      else
        update_location(feature, existing)
      end
    end

    def create_location(feature)
      Geojson.logger.info "  -> creating new location #{feature.location_id}"

      begin
        parent = nil
        if feature.parent_id
          parent = Location.where(geo_id: feature.parent_id).first
          Geojson.logger.error "  -> location #{feature.name}'s parent with geo id #{feature.parent_id} not found" if parent.nil?
        else
          Geojson.logger.info "  -> location #{feature.name} has no parent id and is considered a root"
        end

        Location.create_from_geojson!(parent, feature)

      rescue => ex
        Geojson.logger.error "  -> exception creating location for feature #{feature.name} #{feature.location_id}: #{ex}"
        @failed += 1
      else
        @created += 1
      end
    end

    def update_location(feature, location)
      begin
        location.update_attributes!(lat: feature.center[1], lng: feature.center[1])

        if location.shape.nil?
          location.create_shape!(feature.as_location_shape_attributes)
          Geojson.logger.info "  -> updated location #{location.name} #{location.id} with new shape from feature #{feature.location_id}"
        else
          location.shape.update_attributes!(feature.as_location_shape_attributes)
          Geojson.logger.info "  -> updated location #{location.name} #{location.id} shape #{location.shape.id} from feature #{feature.location_id}"
        end
      rescue => ex
        Geojson.logger.error "  -> exception updating location #{location.id} for feature #{feature.name} #{feature.location_id}: #{ex}"
        @failed += 1
      else
        @updated += 1
      end
    end

  end

end
