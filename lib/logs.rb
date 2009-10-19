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

      log_type = log.attrs["log:type"]
      if @logs.keys.member?(log_type)
        throw LogsException.new("#{log_type}: duplicate log_type")
      end

      @logs[log_type] = log
    end

    def [](log_type)
      return @logs[log_type]
    end

    def types
      return @logs.keys
    end
  end # class Logs
end # module LogStash
