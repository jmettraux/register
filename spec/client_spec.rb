
require File.join(File.dirname(__FILE__), 'spec_helper.rb')


describe Register::Client do

  before(:each) do

    @r = ::Redis.new(REDIS_OPTIONS)
    @r.keys('*').each { |k| @r.del(k) }
  end

  describe '.initialize' do

    it 'connects to redis' do

      h = { '_id' => 'x' }
      @r.set('x', Rufus::Json.encode(h))

      cl = Register::Client.new(REDIS_OPTIONS)

      cl.read('x').should == h
    end
  end

  describe '#read' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    context 'when the item exists' do

      it 'returns the item (hash form)' do

        h = { '_id' => 'x' }
        @r.set('x', Rufus::Json.encode(h))

        item = cl.read('x')

        item.should == h
      end
    end

    context 'when the item does not exist' do

      it 'returns nil' do

        cl.read('nemo').should == nil
      end
    end
  end

  describe '#call' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }
    let(:wo) { Register::Worker.new(REDIS_OPTIONS.merge(:start => false)) }

    it 'returns a ticket id' do

      r = cl.call('system', 'put', {})

      r.class.should == String
    end

    it 'places the call in the _calls list' do

      r = cl.call('nada', 'nada', {})

      tickets = @r.lrange('_calls', 0, -1)

      tickets.length.should == 1
      tickets.first.should match(/nada/)
    end

    it 'returns nil if forget=true' do

      r = cl.call('nada', 'nada', {}, true)

      r.should == nil
    end

    it 'behaves like a "get" when args is nil' do

      ticket = cl.call('system', 'put', nil)

      wo.send(:step)

      res = cl.result(ticket)

      res.first.should == true
      res.last.should match(/^proc do /)
    end
  end

  describe '#result' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    it 'returns nil for a unknown ticket' do

      cl.result('nada').should == nil
    end
  end

  describe '#get' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    it 'raises ItemNotFoundError if there is no item' do

      lambda {
        cl.get('nada', 'nada')
      }.should raise_error(Register::ItemNotFoundError)
    end

    it 'returns nil if there is no value for the key' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 1))

      cl.get('x', 'nada').should == nil
    end

    it 'returns the value if there is one' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 1, 'v' => 2.0))

      cl.get('x', 'v').should == 2.0
    end
  end

  describe '#has_key?' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    it 'raises ItemNotFoundError if there is no item' do

      lambda {
        cl.has_key?('nada', 'nada')
      }.should raise_error(Register::ItemNotFoundError)
    end

    it 'returns false if the item has not got the key' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 1))

      cl.has_key?('x', 'nada').should == false
    end

    it 'returns true if the item has got the key' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 1, 'v' => nil))

      cl.has_key?('x', 'v').should == true
    end

    it 'goes deep' do

      @r.set(
        'x',
        Rufus::Json.encode(
          '_id' => 'x', '_rev' => 1, '_parent' => 'y'))
      @r.set(
        'y',
        Rufus::Json.encode(
          '_id' => 'y', '_rev' => 1, '_parent' => 'z', 'n' => 7))
      @r.set(
        'z',
        Rufus::Json.encode(
          '_id' => 'z', '_rev' => 1, 'n' => 6, 'bottom' => nil))

      cl.has_key?('x', 'bottom').should == true
    end
  end

  describe '#deep_read' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    it 'reads one item when there is no _parent' do

      @r.set('x', Rufus::Json.encode('_id' => 'x', '_rev' => 1))

      cl.deep_read('x').should == { '_id' => 'x', '_rev' => 1 }
    end

    it "reads one item when it's an orphan" do

      @r.set(
        'x',
        Rufus::Json.encode('_id' => 'x', '_rev' => 1, '_parent' => 'n'))

      cl.deep_read('x').should == {
        '_id' => 'x', '_rev' => 1, '_parent' => 'n' }
    end

    it "merges child and parent" do

      @r.set(
        'x',
        Rufus::Json.encode(
          '_id' => 'x', '_rev' => 1, '_parent' => 'y'))
      @r.set(
        'y',
        Rufus::Json.encode(
          '_id' => 'y', '_rev' => 1, '_parent' => 'z', 'n' => 7))
      @r.set(
        'z',
        Rufus::Json.encode(
          '_id' => 'z', '_rev' => 1, 'n' => 6))

      cl.deep_read('x').should == {
        '_id' => 'x', '_rev' => 1, '_parent' => 'y', 'n' => 7 }
    end
  end

  describe '#close' do

    it 'closes the client' do

      cl = Register::Client.new(REDIS_OPTIONS)

      cl.close

      lambda {
        cl.instance_variable_get(:@redis).set('x', 'y')
      }.should raise_error(NoMethodError)
    end
  end
end

