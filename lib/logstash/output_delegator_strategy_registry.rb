module LogStash; class OutputDelegatorStrategyRegistry
  class InvalidStrategyError < StandardError; end
                   
  # This is generally used as a singleton
  # Except perhaps during testing
  def self.instance
    @instance ||= self.new
  end

  def initialize()
    @map = {}
  end

  def classes
    @map.values
  end

  def types
    @map.keys
  end
  
  def class_for(type)
    klass = @map[type]

    if !klass
      raise InvalidStrategyError, "Could not find output delegator strategy of type '#{type}'. Valid strategies: #{@strategy_registry.types}"
    end

    klass
  end

  def register(type, klass)
    @map[type] = klass
  end

end; end
