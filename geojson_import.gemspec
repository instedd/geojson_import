# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'geojson_import/version'

Gem::Specification.new do |spec|
  spec.name          = "geojson_import"
  spec.version       = Geojson::VERSION
  spec.authors       = ["Franco Leonardo Bulgarelli"]
  spec.email         = ["fbulgarelli@manas.com.ar"]
  spec.summary       = "Download and import GADM Geojson"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         =  Dir["lib/**/**"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
