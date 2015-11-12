module Geojson

  class Indexer

    attr_reader :index_name, :client


    def initialize(index_name=nil)
      @index_name = index_name || Settings.elasticsearch_locations_index
      @client = Elasticsearch::Client.new host: Settings.elasticsearch_url#, log: :debug
    end


    def reindex_all!
      delete_index
      create_index
      index_all
    end


    def delete_index
      if client.indices.exists(index: index_name)
        client.indices.delete index: index_name
        Geojson.logger.info "Deleted locations index #{index_name}"
      else
        Geojson.logger.info "No locations index #{index_name} found"
      end
    end


    def create_index
      client.indices.create index: index_name, body: {
        "mappings" => {
          "location" => {
            "properties" => {
              "location_id" => {"type" => "integer", "index" => "not_analyzed"},
              "parent_id" => {"type" => "string", "index" => "not_analyzed"},
              "geo_id" => {"type" => "string", "index" => "not_analyzed"},
              "level" => {"type" => "integer"},
              "name" => {"type" => "string"},
              "shape" => {"type" => "geo_shape"},
              "center" => {"type" => "geo_shape"},
            }
          }
        }
      }
      Geojson.logger.info "Created index #{index_name}"
    end


    def index_all
      Location.roots.each do |root|
        index_tree root.self_and_descendants.includes(:shape)
      end
    end


    def index_tree(locations_tree)
      Geojson.logger.info "Indexing locations in #{locations_tree.first.name}"
      locations_tree.in_groups_of(50).each do |batch|
        begin
          batch.compact!
          client.bulk index: @index_name, type: 'location', body: (batch.map do |location|
            data = location_attributes_for_index(location)
            { index: { data: data, _id: location.geo_id } }
          end)
        rescue => ex
          Geojson.logger.error "  -> error indexing batch #{batch[0].name} to #{batch[-1].name}: #{ex}"
        else
          Geojson.logger.info "  -> indexed locations batch #{batch[0].name} to #{batch[-1].name}"
        end
      end
    end


    def location_attributes_for_index(location)
      attributes = {
        "location_id" => location.id,
        "parent_id" => location.parent_id,
        "geo_id" => location.geo_id,
        "level" => location.depth,
        "name" => location.name,
        "center" => {
          "type" => "point",
          "coordinates" => location.center
        }
      }

      attributes.merge!({
        "shape" => {
          "type" => location.shape.geo_type,
          "coordinates" => location.shape.geo_shape
        }
      }) if location.shape

      return attributes
    end

    def validate_center(location_or_locations)
      if location_or_locations.kind_of?(Location)
        location = location_or_locations
        result = client.search(index: @index_name, body: validate_center_query(location))
        hits = result["hits"]["hits"].map{ |h| h['_id']}

        log_missing_hits(location, hits)
        log_extra_hits(location, hits)
      else
        location_or_locations.each { |l| l.shape && validate_center(l) }
      end
    end

    def validate_center_query(location)
      {
        "query" => {
          "filtered" => {
            "query" => {
              "match_all" => {},
            },
            "filter" => {
              "and" => [
                {
                  "range" => {
                    "level" => { "lte" => location.depth }
                  },
                },
                {
                  "geo_shape" => {
                    "shape" => {
                      "shape" => {
                        "type" => "point",
                        "coordinates" => [location.lng, location.lat]
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      }
    end

    #
    # Returns the geo_id of all locations expected to contain the
    # center of a given location.
    #
    # example: ["209_1_34"] ~~> ["209", "209_1", "209_1_34"]
    #
    def expected_hits(location)
      parts = location.geo_id.split('_')
      fst = parts.shift
      parts.inject([fst]) { |r,x| r << "#{r.last}_#{x}" }
    end

    def log_missing_hits(location, hits)
      missing_hits = expected_hits(location) - hits
      if missing_hits.any?
        if missing_hits.delete(location.geo_id)
          Geojson.logger.warn("Location #{location.name} (#{location.id}) has a center #{location.center} outside of its polygon")
        end

        missing_hit_names = Location.where(geo_id: missing_hits).pluck(:name)
        Geojson.logger.warn("Location #{location.name} (#{location.id}) has a center #{location.center} outside of #{'parent'.pluralize(missing_hits.length)} #{missing_hit_names.to_sentence}")
      end
    end

    def log_extra_hits(location, hits)
      extra_hits = hits - expected_hits(location)
      if extra_hits.any?
        extra_hit_names = Location.where(geo_id: extra_hits).pluck(:name)
        Geojson.logger.warn("Location #{location.name} (#{location.id}) has a center #{location.center} inside non #{'parent'.pluralize(extra_hits.length)} #{extra_hit_names.to_sentence}")
      end
    end

  end


end
