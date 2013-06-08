# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'flay_away/version'

Gem::Specification.new do |gem|
  gem.name          = "flay_away"
  gem.version       = FlayAway::VERSION
  gem.authors       = ["Eugene Kalenkovich"]
  gem.email         = ["rubify@softover.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency 'flay', '=2.3.0'
  gem.add_dependency 'ruby_parser',  '=3.1.3'
  gem.add_dependency 'actionpack', '~>3.2'
  gem.add_dependency 'flay-haml'
end
