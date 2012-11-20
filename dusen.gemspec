$:.push File.expand_path("../lib", __FILE__)
require "dusen/version"

Gem::Specification.new do |s|
  s.name = 'dusen'
  s.version = Dusen::VERSION
  s.authors = ["Henning Koch"]
  s.email = 'henning.koch@makandra.de'
  s.homepage = 'https://github.com/makandra/dusen'
  s.summary = 'Maps Google-like queries (words, "phrases", qualified:fields) to ActiveRecord scope chains'
  s.description = s.summary

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('rails')

end
