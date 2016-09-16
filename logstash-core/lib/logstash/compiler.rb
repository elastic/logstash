module LogStash; class Compiler
  def self.compile(config_str, filename="<unknown>")
    grammar = LogStashConfigParser.new
    config = grammar.parse(config_str)

    if config.nil?
      raise ConfigurationError, grammar.failure_reason
    end
    
    compiled = config.compile(filename)
  end
end; end
