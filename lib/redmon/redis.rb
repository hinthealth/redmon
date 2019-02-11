require 'redis'

module Redmon
  module Redis
    extend self

    UNSUPPORTED = [
      :eval,
      :psubscribe,
      :punsubscribe,
      :subscribe,
      :unsubscribe,
      :unwatch,
      :watch
    ]

    def redis
      @redis ||= ::Redis.new(url: redis_url)
    end

    def redis_url
      Redmon.config.redis_instances[redis_instance.to_sym]
    end

    def redis_instance_valid?
      Redmon.config.redis_instances.key?(redis_instance.to_sym)
    end

    def redis_instance_url_valid?
      redis_url.present?
    end

    def redis_instance
      default_redis_instance
    end

    def default_redis_instance
      Redmon.config.redis_instances.keys.first
    end

    def ns
      Redmon.config.namespace
    end

    def anonymize_redis_url(url)
      return unless url

      url.gsub(/\w*:\w*@/, '')
    end

    def anonymized_redis_url
      @anonymized_redis_url ||= anonymize_redis_url(redis_url)
    end

    def redis_host
      anonymized_redis_url.gsub('redis://', '')
    end

    def config
      redis.config :get, '*' rescue {}
    end

    def unquoted
      %w{string OK} << '(empty list or set)'
    end

    def supported?(cmd)
      !UNSUPPORTED.include? cmd
    end

    def empty_result
      '(empty list or set)'
    end

    def unknown(cmd)
      "(error) ERR unknown command '#{cmd}'"
    end

    def wrong_number_of_arguments_for(cmd)
      "(error) ERR wrong number of arguments for '#{cmd}' command"
    end

    def connection_refused
      "Could not connect to Redis at #{anonymized_redis_url.gsub(/\w*:\/\//, '')}: Connection refused"
    end

    def stats_key
      "#{ns}:redis:#{redis_host}:stats"
    end
  end
end
