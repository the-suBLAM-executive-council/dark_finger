# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dark_finger/version'

Gem::Specification.new do |spec|
  spec.name          = "dark_finger"
  spec.version       = DarkFinger::VERSION
  spec.authors       = ["Professor Wang Matrix PhD", "Urban Cougar"]
  spec.email         = ["professor.wang.matrix.phd@gmail.com", "urbancougarltd@gmail.com"]

  spec.summary       = "ActiveModel layout cop for Rubocop"
  spec.homepage      = "https://github.com/the-suBLAM-executive-council/dark_finger"
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.11"
  spec.add_development_dependency "pry", "~> 0.14.0"
  spec.add_runtime_dependency 'rubocop', '~> 1.36.0'
end
