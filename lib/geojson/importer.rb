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
      Rails.logger.warn "No files provided for importing." if filenames.blank?
      filenames.sort.map do |filename|
        Rails.logger.info "Processing file: #{filename}"
        FeatureCollection.from_path(filename).features do |feature|
          import_feature(feature)
        end
      end
      Rails.logger.warn "\n---\n\nCreated\t#{@created}\nUpdated\t#{@updated}\nFailed\t#{@failed}\nTotal processed\t#{@created+@updated+@failed}"
    end

    def import_feature(feature)
      Rails.logger.info "  #{feature.name} (id: #{feature.location_id}) at #{feature.center}"
      existing = Location.where(geo_id: feature.location_id).first

      if existing.nil?
        create_location(feature)
      else
        update_location(feature, existing)
      end
    end

    def create_location(feature)
      Rails.logger.info "  -> creating new location #{feature.location_id}"

      begin
        parent = nil
        if feature.parent_id
          parent = Location.where(geo_id: feature.parent_id).first
          Rails.logger.error "  -> location #{feature.name}'s parent with geo id #{feature.parent_id} not found" if parent.nil?
        else
          Rails.logger.info "  -> location #{feature.name} has no parent id and is considered a root"
        end

        shape = LocationShape.new feature.as_location_shape_attributes

        Location.create!\
          name: feature.name,
          geo_id: feature.location_id,
          lat: feature.center[1],
          lng: feature.center[0],
          parent: parent,
          shape: shape
      rescue => ex
        Rails.logger.error "  -> exception creating location for feature #{feature.name} #{feature.location_id}: #{ex}"
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
          Rails.logger.info "  -> updated location #{location.name} #{location.id} with new shape from feature #{feature.location_id}"
        else
          location.shape.update_attributes!(feature.as_location_shape_attributes)
          Rails.logger.info "  -> updated location #{location.name} #{location.id} shape #{location.shape.id} from feature #{feature.location_id}"
        end
      rescue => ex
        Rails.logger.error "  -> exception updating location #{location.id} for feature #{feature.name} #{feature.location_id}: #{ex}"
        @failed += 1
      else
        @updated += 1
      end
    end

  end

end
