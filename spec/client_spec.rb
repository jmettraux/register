
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

      cl.read('x').should == Register::Item.new(h)
    end
  end

  describe '#read' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    context 'when the item exists' do

      it 'returns the item (hash form)' do

        h = { '_id' => 'x' }
        @r.set('x', Rufus::Json.encode(h))

        item = cl.read('x')

        item.should == Register::Item.new(h)
      end
    end

    context 'when the item does not exist' do

      it 'returns nil' do

        cl.read('nemo').should == nil
      end
    end
  end

  describe '#get' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    context 'when the item exists' do

      it 'returns the value in the item' do

        h = { '_id' => 'x', 'k' => 'v' }
        @r.set('x', Rufus::Json.encode(h))

        cl.get('x', 'k').should == 'v'
      end
    end

    context 'when the item does not exist' do

      it 'raises NoMethodError' do

        lambda {
          cl.get('x', 'k')
        }.should raise_error(NoMethodError)
      end
    end
  end

  describe '#call' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

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
  end

  describe '#success?' do

    let(:cl) { Register::Client.new(REDIS_OPTIONS) }

    it 'returns nil for a unknown ticket' do

      cl.success?('nada').should == nil
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

