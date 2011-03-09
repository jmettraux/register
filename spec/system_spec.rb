
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe 'the system items' do

  let(:wo) { Register::Worker.new(REDIS_OPTIONS.merge(:start => false)) }
  let(:cl) { Register::Client.new(REDIS_OPTIONS) }

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe "'echo'" do

    it 'returns a string' do

      ticket = cl.call('system', 'echo', %w[ hello world ])

      wo.send(:step)

      cl.result(ticket).should == [ true, 'hello world' ]
    end
  end

  describe "'put'" do

    it 'puts an item' do

      ticket = cl.call('system', 'put', '_id' => 'x')

      wo.send(:step)

      cl.result(ticket).should == [ true, 1 ]
      @r.get('x').should == Rufus::Json.encode('_id' => 'x', '_rev' => 1)
    end
  end
end

