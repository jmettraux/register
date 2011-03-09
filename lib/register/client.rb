#--
# Copyright (c) 2011-2011, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Register

  class ItemNotFoundError < StandardError

    attr_reader :item_id

    def initialize(item_id)

      @item_id = item_id

      super("no item '#{item_id}'")
    end
  end

  class Client

    attr_reader :redis

    def initialize(redis_opts)

      @redis = Redis.new(redis_opts)
    end

    def read(item_id)

      s = @redis.get(item_id)

      s ? Rufus::Json.decode(s) : nil
    end

    def call(item_id, key, args, forget=false)

      ticket = forget ? nil : @redis.incr('_ticket').to_s

      if item_id == 'system' and @redis.get('system').nil?
        Register.put_system(@redis)
      end

      @redis.rpush(
        '_calls',
        Rufus::Json.encode(
          'ticket' => ticket,
          'item_id' => item_id,
          'key' => key,
          'args' => args))

      ticket
    end

    def get(item_id, key)

      item = deep_read(item_id)

      raise ItemNotFoundError.new(item_id) unless item

      item[key]
    end

    def deep_read(item_id)

      line = []

      loop do

        item = read(item_id)

        break unless item

        line << item
        parent_id = item['_parent']

        break unless parent_id

        item_id = parent_id
      end

      line.reverse.inject(line.pop) { |parent, child| parent.merge!(child) }
    end

    def result(ticket, delete=true)

      res = @redis.hget('_tickets', ticket)
      @redis.hdel('_tickets', ticket) if res && delete

      res ? Rufus::Json.decode(res) : nil
    end

    # Blocking call, only return with the result.
    #
    def bcall(item_id, key, args)

      tic = call(item_id, key, args)
      res = nil

      loop do
        sleep 0.100
        res = result(tic)
        break if res
      end

      res
    end

    def put(item)

      call('system', 'put', item)
    end

    def close

      @redis.quit
      @redis = nil
    end
  end
end

