# encoding: utf-8

Gem::Specification.new do |s|

  s.name = 'register'
  s.version = File.read('lib/register/version.rb').match(/VERSION = '([^']+)'/)[1]
  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux@gmail.com' ]
  s.homepage = 'http://register.lambda.io'
  s.rubyforge_project = 'ruote'
  s.summary = 'fun experiment with Redis'
  s.description = %q{
Redis and a few ideas borrowed from Javascript, CouchDB and actors
}

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    'Rakefile',
    'lib/**/*.rb', 'spec/**/*.rb', 'test/**/*.rb',
    '*.gemspec', '*.txt', '*.rdoc', '*.md'
  ]

  s.add_runtime_dependency 'sourcify', '0.4.2'
  s.add_runtime_dependency 'rufus-json', '>= 0.2.5'
  s.add_runtime_dependency 'redis', '2.1.1'

  s.add_development_dependency 'json'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '>= 2.5.0'

  s.require_path = 'lib'
end

