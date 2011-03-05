
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Register::Worker do

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe '.initialize' do
  end
end

