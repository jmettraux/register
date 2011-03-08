
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe 'the system items' do

  let(:wo) { Register::Worker.new(REDIS_OPTIONS, false) }

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe "'put'" do

    it 'flips burgers'
  end
end

