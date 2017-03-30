# encoding: utf-8
module LogStash
  module Retryable
    # execute retryable code block
    # @param [Hash] options retryable options
    # @option options [Fixnum] :tries retries to perform, default 1, set to 0 for infinite retries. 1 means that upon exception the block will be retried once
    # @option options [Fixnum] :base_sleep seconds to sleep on first retry, default 1
    # @option options [Fixnum] :max_sleep max seconds to sleep upon exponential backoff, default 1
    # @option options [Exception] :rescue exception class list to retry on, defaults is Exception, which retries on any Exception.
    # @option options [Proc] :on_retry call the given Proc/lambda before each retry with the raised exception as parameter
    def retryable(options = {}, &block)
      options = {
        :tries => 1,
        :rescue => Exception,
        :on_retry => nil,
        :base_sleep => 1,
        :max_sleep => 1,
      }.merge(options)

      rescue_classes = Array(options[:rescue])
      max_sleep_retry = Math.log2(options[:max_sleep] / options[:base_sleep])
      retry_count = 0

      begin
        return yield(retry_count)
      rescue *rescue_classes => e
        raise e if options[:tries] > 0 && retry_count >= options[:tries]

        options[:on_retry].call(retry_count + 1, e) if options[:on_retry]

        # dont compute and maybe overflow exponent on too big a retry count
        seconds = retry_count < max_sleep_retry ? options[:base_sleep] * (2 ** retry_count) : options[:max_sleep]
        sleep(seconds)

        retry_count += 1
        retry
      end
    end
  end
end
