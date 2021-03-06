# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fast_change_table/version"

Gem::Specification.new do |s|
  s.name        = "fast_change_table"
  s.version     = FastChangeTable::VERSION
  s.authors     = ["Grady Griffin"]
  s.email       = ["gradyg@izea.com"]
  s.homepage    = "https://github.com/moxie/fast_change_table"
  s.summary     = %q{Faster table changes}
  s.description = %q{Uses table duplication to speed up migrations on large tables}

  s.rubyforge_project = "fast_change_table"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    s.add_runtime_dependency('activerecord', '>= 2.3')
    s.add_development_dependency("rspec")
    s.add_development_dependency("mysql2")
  else
    s.add_dependency('activerecord', '>= 2.3')
    s.add_development_dependency("rspec")
    s.add_development_dependency("mysql2")
  end
end
