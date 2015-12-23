require 'geojson_import/version'

require 'geojson_import/csv_import'
require 'geojson_import/downloader'
require 'geojson_import/feature'
require 'geojson_import/feature_collection'
require 'geojson_import/importer'
require 'geojson_import/indexer'
require 'geojson_import/point_checker'
require 'geojson_import/point_collector'

require 'logger'

module Geojson

  def self.logger
    @logger ||= Rails.logger rescue Logger.new(STDOUT)
  end

end
