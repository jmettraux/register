
$:.unshift('lib')

require 'register'


Dir['spec/support/**/*.rb'].each { |f| require(f) }

RSpec.configure do |config|

  config.mock_with :rspec

  #config.include NodeHelper
end

