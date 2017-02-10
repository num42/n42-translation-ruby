# -*- encoding: utf-8 -*-
require File.expand_path("../lib/n42translation/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "n42translation"
  s.version     = N42translation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Wolfgang Lutz"]
  s.email       = ["wlut@num42.de"]
  s.homepage    = "http://num42.de"
  s.summary     = "Translation helper to build translations files from a single source"
  s.description = "Supports ruby on rails, ios and android"
  s.license       = "MIT"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "n42translation"

  s.add_development_dependency "bundler", "~> 1.6"

  s.add_runtime_dependency "thor", "~> 0.19"
  s.add_runtime_dependency "builder", "~> 3.2"
  s.add_runtime_dependency "activesupport", "~> 4.2"
  s.add_runtime_dependency "write_xlsx", "~> 0.83"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
