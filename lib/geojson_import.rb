require "geojson_import/version"

module Geojson

  def self.logger
    @logger ||= ActiveSupport::Logger.new
  end

end
