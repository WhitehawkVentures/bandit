module Bandit
  class RedisStorage < BaseStorage
    def initialize(config)
      require 'redis'
      require 'connection_pool'

      if config[:url]
        uri = URI.parse(config[:url])
        config[:host] = uri.host
        config[:port] = uri.port
        config[:password] = uri.password
      else
        config[:host] ||= 'localhost'
        config[:port] ||= 6379
      end
      config[:db] ||= "bandit"

      @redis = ConnectionPool.new(size: 10, timeout: 5) {
        Redis.new config
      }
    end

    # increment key by count
    def incr(key, count=1)
      with_failure_grace(count) {
        @redis.with do |conn|
          conn.incrby(key, count)
        end
      }
    end

    # increment hash field by count
    def incr_hash(key, field, count)
      with_failure_grace(count) {
        @redis.with do |conn|
          conn.hincrby(key, field, count)
        end
      }
    end

    def redis
      @redis
    end

    # initialize key if not set
    def init(key, value)
      with_failure_grace(value) {
        @redis.with do |conn|
          conn.set(key, value) if get(key, nil).nil? 
        end
      }
    end

    # get key if exists, otherwise 0
    def get(key, default=0)
      @redis.with do |conn|
        with_failure_grace(default) {
          val = conn.get(key)
          return default if val.nil?
          val.numeric? ? val.to_i : val
        }
      end
    end

    # hget key if exists, otherwise 0
    def hget(key, field, default=0)
      @redis.with do |conn|
        with_failure_grace(default) {
          val = conn.hget(key, field)
          return default if val.nil?
          val.numeric? ? val.to_i : val
        }
      end
    end
    
    def mget(keys)
      return [] unless keys && keys.length > 0
      @redis.with do |conn|
        conn.mget(*keys)
      end
    end

    # set key with value, regardless of whether it is set or not
    def set(key, value)
      with_failure_grace(value) {
        @redis.with do |conn|
          conn.set(key, value)
        end
      }
    end

    def expire(key, value)
      with_failure_grace(value) {
        @redis.with do |conn|
          conn.expire(key, value)
        end
      }
    end

    def del(key)
      with_failure_grace(key) {
        @redis.with do |conn|
          conn.del(key)
        end
      }
    end

    def sadd(key, value)
      with_failure_grace(value) {
        @redis.with do |conn|
          conn.sadd(key, value)
        end
      }
    end

    def smembers(key)
      @redis.with do |conn|
        conn.smembers(key)
      end
    end

    def clear!
      with_failure_grace(nil) {
        @redis.with do |conn|
          conn.flushdb
        end
      }
    end
  end
end
