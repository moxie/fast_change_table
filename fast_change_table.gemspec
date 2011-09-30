# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fast_change_table/version"

Gem::Specification.new do |s|
  s.name        = "fast_change_table"
  s.version     = FastChangeTable::VERSION
  s.authors     = ["Joe Peduto"]
  s.email       = ["joey@izea.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "fast_change_table"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency('activerecord', '~> 2.3')
  else
    s.add_dependency('activerecord', '~> 2.3')
  end
end
