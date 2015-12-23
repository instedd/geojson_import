module Geojson

  class Importer
    include Geojson::CSVImport

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
        load_csv_for(filename)
        FeatureCollection.from_path(filename).features do |feature|
          import_feature(feature)
        end
      end
      Geojson.logger.warn "\n---\n\nCreated\t#{@created}\nUpdated\t#{@updated}\nFailed\t#{@failed}\nTotal processed\t#{@created+@updated+@failed}"
    end

    def import_feature(feature)
      Geojson.logger.info " #{feature.name} (id: #{feature.location_id}) at #{feature.center}"
      existing = Location.where(geo_id: feature.location_id).first
      merge_csv_data(feature)

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
        location.update_from_geojson!(feature)
        Geojson.logger.info "  -> updated location #{feature.name}"
      rescue => ex
        Geojson.logger.error "  -> exception updating location #{location.id} for feature #{feature.name} #{feature.location_id}: #{ex}"
        @failed += 1
      else
        @updated += 1
      end
    end

    def merge_csv_data(feature)
      data = @csvdata[feature.location_id]
      return if not data

      name = data["NAME_#{feature.level}"] || (feature.level == 0 && data["NAME_ENGLI"])
      unless name.blank?
        name.gsub!(/<U\+([A-F0-9]+)>/) {|match| [$1.hex].pack('U')}
        Geojson.logger.info "  -> using name #{name} from CSV"
        feature.name = name
      end

      center = [data["CENTER_LNG"], data["CENTER_LAT"]]
      if center.all?(&:present?)
        Geojson.logger.info "  -> using center #{center} from CSV"
        feature.center = center.map(&:to_f)
      end
    end

  end

end
