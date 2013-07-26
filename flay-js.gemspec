# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "flay-js"
  gem.version       = "0.0.1"
  gem.authors       = ["Eugene Kalenkovich"]
  gem.email         = ["rubify@softover.com"]
  gem.description   = "Helps flay to find duplicate code in javascript files"
  gem.summary       = "Flay your JS"
  gem.homepage      = "https://github.com/UncleGene/flay-js"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'flay', '~> 2.4'
  gem.add_dependency 'rkelly'
end
