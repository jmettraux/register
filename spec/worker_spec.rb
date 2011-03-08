
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Register::Worker do

  let(:wo) { Register::Worker.new(REDIS_OPTIONS.merge(:start => false)) }

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe '.initialize' do

    it 'connects to redis' do

      wo.instance_variable_get(:@client).should_not == nil
    end
  end

  describe '#step' do

    it 'returns after 1 second when there are no calls' do

      t = Time.now

      wo.send(:step)

      (Time.now - t).should > 1.0
    end

    it 'process calls' do

      ticket = wo.client.call('nada', 'nada', {})

      wo.send(:step)

      sleep 0.200

      res = wo.client.result(ticket)

      res.should == [ false, "no item 'nada'" ]
    end
  end
end

