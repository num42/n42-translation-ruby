# -*- encoding: utf-8 -*-
require File.expand_path("../lib/n42translation/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "n42translation"
  s.version     = N42translation::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Wolfgang Lutz"]
  s.email       = ["wlut@num42.de"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "n42translation"

  s.add_development_dependency "bundler", ">= 1.0.0"

  s.add_runtime_dependency "thor"
  s.add_runtime_dependency "builder"
  s.add_runtime_dependency "activesupport"
  s.add_runtime_dependency "write_xlsx"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
