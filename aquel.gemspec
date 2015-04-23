# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aquel/version'

Gem::Specification.new do |spec|
  spec.name          = "aquel"
  spec.version       = Aquel::VERSION
  spec.authors       = ["youpy"]
  spec.email         = ["youpy@buycheapviagraonlinenow.com"]
  spec.summary       = %q{a(nything) que(ry) l(anguage)}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pg_query"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "nokogiri"
end
