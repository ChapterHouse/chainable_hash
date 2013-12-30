# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chainable_hash/version'

Gem::Specification.new do |spec|
  spec.name          = "chainable_hash"
  spec.version       = ChainableHash::VERSION
  spec.authors       = ["Frank Hall"]
  spec.email         = ["ChapterHouse.Dune@gmail.com"]
  spec.description   = %q{A hash that can be chained to others in an inheritable fashion.}
  spec.summary       = %q{Designed for class level attributes, ChainableHash is designed for maintaining hashes in an inheritable fashion such that changes in the parent can be reflected in the children but not vice versa.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
