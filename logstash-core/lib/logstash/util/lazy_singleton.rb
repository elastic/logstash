require 'thread' # Mutex

# A [LazySingleton] wraps the result of the provided block,
# which is guaranteed to be called at-most-once, even if the
# block's return value is nil.
class ::LogStash::Util::LazySingleton

  def initialize(&block)
    @mutex = Mutex.new
    @block = block
    @instantiated = false
  end

  def instance
    unless @instantiated
      @mutex.synchronize do
        unless @instantiated
          @instance = @block.call
          @instantiated = true
        end
      end
    end

    return @instance
  end

  def reset!
    @mutex.synchronize do
      @instantiated = false
      @instance = nil
    end
  end
end
