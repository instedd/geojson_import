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
        Rails.logger.info "Deleted locations index #{index_name}"
      else
        Rails.logger.info "No locations index #{index_name} found"
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
      Rails.logger.info "Created index #{index_name}"
    end


    def index_all
      Location.roots.each do |root|
        index_tree root.self_and_descendants.includes(:shape)
      end
    end


    def index_tree(locations_tree)
      Rails.logger.info "Indexing locations in #{locations_tree.first.name}"
      locations_tree.in_groups_of(50).each do |batch|
        begin
          batch.compact!
          client.bulk index: @index_name, type: 'location', body: (batch.map do |location|
            data = location_attributes_for_index(location)
            { index: { data: data, _id: location.geo_id } }
          end)
        rescue => ex
          Rails.logger.error "  -> error indexing batch #{batch[0].name} to #{batch[-1].name}: #{ex}"
        else
          Rails.logger.info "  -> indexed locations batch #{batch[0].name} to #{batch[-1].name}"
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
        Rails.logger.warn("Location #{location.name} (#{location.id}) has a center #{location.center} outside of its polygon") if result["hits"]["total"] == 0
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
                  "term" => {
                    "location_id" => location.id
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

  end


end
