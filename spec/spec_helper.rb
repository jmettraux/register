
$:.unshift('lib')

begin
  require 'yajl'
rescue LoadError
  require 'json'
end

require 'register'

REDIS_OPTIONS = { :db => 13 }


Dir['spec/support/**/*.rb'].each { |f| require(f) }

RSpec.configure do |config|

  config.mock_with :rspec

  #config.include NodeHelper
end

