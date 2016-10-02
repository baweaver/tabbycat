# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tabbycat/version'

Gem::Specification.new do |spec|
  spec.name          = "tabbycat"
  spec.version       = Tabbycat::VERSION
  spec.authors       = ["Brandon Weaver"]
  spec.email         = ["keystonelemur@gmail.com"]
  spec.summary       = %q{Stuff to help me grok a bunch of tab files for classtab}
  spec.homepage      = "https://github.com/baweaver/tabbycat"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "launchy"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "highline"
  spec.add_runtime_dependency "typhoeus"
end
