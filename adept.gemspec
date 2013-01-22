# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'adept/version'

Gem::Specification.new do |gem|
  gem.name          = "ruby-adept"
  gem.version       = Adept::VERSION
  gem.authors       = ["Kyle J. Temkin"]
  gem.email         = ["ktemkin@binghamton.edu"]
  gem.description   = 
    'Ruby library for working with Digilent devices via the Adept SDK.
     Provides both low-level wrappers for the Adept SDK elements and high-level
     interfaces, including simple programming and configuration routines.'
  gem.summary       = "Framework for working with Digilent Adept devices."
  gem.homepage      = "http://www.github.com/ktemkin/ruby-adept"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
