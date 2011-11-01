# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tabloid/version"

Gem::Specification.new do |s|
  s.name        = "tabloid"
  s.version     = Tabloid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Keith Gaddis"]
  s.email       = ["keith.gaddis@gmail.com"]
  s.homepage    = "http://github.com/Inductive/tabloid"
  s.summary     = %q{ Tabloid allows the creation of cacheable report data using a straightforward DSL and output to HTML, CSV, and more to come.}
  s.description = %q{ Tabloid allows the creation of cacheable report data using a straightforward DSL and output to HTML, CSV, and more to come.}

  s.rubyforge_project = "tabloid"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency "rspec"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "dalli"
  s.add_runtime_dependency "fastercsv"
  s.add_runtime_dependency "builder"
  s.add_runtime_dependency "pdfkit"
end
