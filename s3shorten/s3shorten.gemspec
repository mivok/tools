# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 's3shorten'
  spec.version       = '0.0.1'
  spec.authors       = ["Mark Harrison"]
  spec.email         = ["mark@mivok.net"]
  spec.summary       = %q{URL shortener tool}
  spec.description   = %q{URL shortener tool using S3 and fog}
  spec.homepage      = "http://github.com/mivok/tools"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_dependency 'mixlib-config', '~> 2.1.0'
  spec.add_dependency 'aws-sdk', '~> 1.52.0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry', '~> 0.10'
end
