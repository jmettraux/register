
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Register::Client do

  describe '.initialize' do

    it 'connects to redis' do

      cl = Register::Client.new(:db => 13)
    end
  end
end

