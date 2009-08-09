module LogStash
  class LogsException < StandardError
  end

  class Logs
    def initialize
      @logs = {}
    end

    def register(log)
      if not log.is_a?(Log)
        throw LogsException.new("#{log} is not a Log object")
      end

      name = log.attrs["log:name"]
      if @logs.keys.member?(name)
        throw LogsException.new("#{name}: duplicate log:name")
      end

      @logs[name] = log
    end

    def [](name)
      return @logs[name]
    end
  end # class Logs
end # module LogStash
