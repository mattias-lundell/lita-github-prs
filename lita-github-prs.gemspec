Gem::Specification.new do |spec|
  spec.name          = 'lita-github-prs'
  spec.version       = '0.1.0'
  spec.authors       = ['Mattias Lundell']
  spec.email         = ['mattias@lundell.com']
  spec.description   = 'Slack bot github pull request tool'
  spec.summary       = 'Collection of github pull request tools as a slack bot'
  spec.homepage      = 'https://github.com/mattias-lundell/lita-github-prs'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }
  spec.required_ruby_version = '>= 2.3.0'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.7'
  spec.add_runtime_dependency 'lita-slack'
  spec.add_runtime_dependency 'octokit'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
end
