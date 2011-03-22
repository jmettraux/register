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

  class CallError < StandardError

    attr_reader :result

    def initialize(result)

      @result = result
      super("result : #{Rufus::Json.encode(result)}")
    end
  end

  class Worker

    attr_reader :client
    attr_reader :running

    # TODO : document :start option
    # TODO : document :run_in_thread option
    #
    def initialize(redis_opts)

      in_thread = redis_opts.delete(:run_in_thread)

      start = redis_opts.delete(:start)
      start = start.nil? ? true : start

      @client = Register::Client.new(redis_opts)
      @running = false

      if in_thread
        @thread = Thread.new { run }
      elsif start
        run
      end
    end

    def run

      @running = true

      loop do
        break if @running == false
        step
      end
    end

    def stop

      @running = false
    end

    def shutdown

      @client.close
    end

    protected

    def step

      call = @client.redis.blpop('_calls', 1)

      return if call == nil

      call = Rufus::Json.decode(call.last)

      item = @client.read(call['item_id'])

      if item.nil?
        reply(call, false, "no item '#{call['item_id']}'")
      elsif call['args']
        do_call(item, call)
      else
        reply(call, true, item[call['key']])
      end
    end

    def reply(call, success, result)

      if ticket = call['ticket']

        @client.redis.hset(
          '_tickets',
          ticket,
          Rufus::Json.encode([ success, result ]))

      #else
        # no ticket given back
      end
    end

    def do_call(item, call)

      item = Register::Item.new(@client, item)

      key = item.get(call['key'])

      return reply(call, false, "unknown key '#{call['key']}'") unless key

      prc = eval(key, item.instance_eval { binding })

      begin
        res = prc.call(call['args'])
        reply(call, true, res)
      rescue CallError => ce
        reply(call, false, ce.result)
      end

    rescue => e
      reply(call, false, [ e.to_s, e.backtrace ])
    end
  end
end

