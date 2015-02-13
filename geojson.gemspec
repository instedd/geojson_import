# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'geojson/version'

Gem::Specification.new do |spec|
  spec.name          = "geojson"
  spec.version       = Geojson::VERSION
  spec.authors       = ["Franco Leonardo Bulgarelli"]
  spec.email         = ["fbulgarelli@manas.com.ar"]
  spec.summary       = "Download and import GADM Geojson"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
