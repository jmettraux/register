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


require 'redis'
require 'rufus-json'


module Register

  class Client

    def initialize(redis_opts)

      @redis = Redis.new(redis_opts)
    end

    def read(item_id)

      from_json(@redis.get(item_id))
    end

    def get(item_id, key)

      if item = read(item_id)
        item[key]
      else
        raise Register::MissingItemError.new(item_id)
      end
    end

    def call(item_id, key, message)

      # TODO : place order in order list
    end

    def close

      @redis.quit
      @redis = nil
    end

    protected

    def from_json(s)

      s ? Rufus::Json.decode(s) : nil
    end

    #LOCK_KEY = /-lock$/

    # A locking mecha.
    #
    # Mostly inspired from http://code.google.com/p/redis/wiki/SetnxCommand
    #
    def lock(key)

      kl = "#{key}-lock"

      loop do

        r = @redis.setnx(kl, Time.now.to_f.to_s)

        break if r != false
          # lock acquired successfully

        t = @redis.get(kl)

        @redis.del(kl) if t && Time.now.to_f - t.to_f > 60.0
          # after 1 minute, locks time out

        sleep 0.007 # let's try to lock again after a while
      end

      #@redis.expire(kl, 2)
        # this doesn't work, it makes the next call to setnx succeed

      result = yield

      @redis.del(kl)

      result
    end
  end
end

