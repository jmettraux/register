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

  def self.put_system(redis)

    redis.set(

      'system',

      Item.new(
        '_id' => 'system',
        '_rev' => '0',

        'put' => proc { |item|

          rev = item['_rev']

          Register.lock(redis, item['_id']) do

            current = @client.read_h(item['_id'])

            current_rev = current ? current['_rev'] : nil

            if current_rev && rev != current_rev

              raise CallError.new(current_rev)

            elsif rev && current_rev.nil?

              raise CallError.new(nil)

            else

              nrev = (rev || 0) + 1

              redis.set(
                item['_id'],
                Rufus::Json.encode(item.merge('_rev' => nrev)))

              # success...

              nrev
            end
          end
        }.to_source,

        'delete' => proc { |item|

          item_id, item_rev = if item.is_a?(Hash)
            [ item['_id'], item['_rev'] ]
          else
            item
          end

          Register.lock(redis, item_id) do

            current = @client.read_h(item['_id'])
            current_rev = current ? current['_rev'] : nil

            if current.nil?

              raise CallError.new(nil)

            elsif current_rev != item_rev

              raise CallError.new(current_rev)

            else

              redis.del(item_id)

              current_rev
            end
          end
        }.to_source

      ).to_json)
  end

  # A locking mecha.
  #
  # Mostly inspired from http://code.google.com/p/redis/wiki/SetnxCommand
  #
  def self.lock(redis, key)

    kl = "#{key}-lock"

    loop do

      break if redis.setnx(kl, Time.now.to_f.to_s) != false
        # locking successful

      #
      # already locked

      t = redis.get(kl)

      redis.del(kl) if t && Time.now.to_f - t.to_f > 60.0
        # after 1 minute, locks time out

      sleep 0.007 # let's try to lock again after a while
    end

    #redis.expire(kl, 2)
      # this doesn't work, it makes the next call to setnx succeed

    result = yield

    redis.del(kl)

    result
  end
end

