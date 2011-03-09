
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe 'the system items' do

  let(:wo) { Register::Worker.new(REDIS_OPTIONS.merge(:start => false)) }
  let(:cl) { Register::Client.new(REDIS_OPTIONS) }

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe "an unknown system call" do

    it "returns [ false, \"unknown key 'nada'\" ]" do

      ticket = cl.call('system', 'nada', {})

      wo.send(:step)

      cl.result(ticket).should == [ false, "unknown key 'nada'" ]
    end
  end

  describe "'put'" do

    it 'puts an item' do

      ticket = cl.call('system', 'put', '_id' => 'x')

      wo.send(:step)

      cl.result(ticket).should == [ true, 1 ]
      @r.get('x').should == Rufus::Json.encode('_id' => 'x', '_rev' => 1)
    end

    it 'returns [ true, 1 ] when the first put is successful' do

      ticket = cl.call('system', 'put', '_id' => 'x')

      wo.send(:step)

      cl.result(ticket).should == [ true, 1 ]
      @r.get('x').should == Rufus::Json.encode('_id' => 'x', '_rev' => 1)
    end

    it 'returns [ true, nrev ] when successful' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 7))

      ticket = cl.call('system', 'put', '_id' => 'x', '_rev' => 7)

      wo.send(:step)

      cl.result(ticket).should == [ true, 8 ]
      @r.get('x').should == Rufus::Json.encode('_id' => 'x', '_rev' => 8)
    end

    it 'returns [ false, current_rev ] if the item is out of date' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 7))

      ticket = cl.call('system', 'put', '_id' => 'x', '_rev' => 6)

      wo.send(:step)

      cl.result(ticket).should == [ false, 7 ]
    end

    it 'returns [ false, nil ] when the item is gone' do

      ticket = cl.call('system', 'put', '_id' => 'x', '_rev' => 6)

      wo.send(:step)

      cl.result(ticket).should == [ false, nil ]
    end
  end
end

