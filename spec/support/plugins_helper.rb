# encoding: utf-8


class LogStash::Inputs::MockGenerator < LogStash::Inputs::Base

  config_name "mock_generator"
  default :codec, "plain"

  config :message, :validate => :string, :default => "Hello world!"
  config :lines, :validate => :array
  config :count, :validate => :number, :default => 0

  def register
    @count = Array(@count).first
  end

  def run(queue)
    i = 0
    @lines = [@message] if @lines.nil?
    while (i < @count)
      @lines.each do |line|
        @codec.decode(line.clone) do |event|
          decorate(event)
          event["sequence"] = i
          queue << event
        end
        i+=1
      end
    end
  end
end

class LogStash::Filters::Mock < LogStash::Filters::Base
  config_name "mock_filter"

  def register; end

  def filter(event)
    filter_matched(event)
  end
end

class LogStash::Filters::MockClone < LogStash::Filters::Base

  config_name "mock_clone"

  config :clones, :validate => :array, :default => []

  def register; end

  def filter(event)
    return unless filter?(event)
    @clones.each do |type|
      clone = event.clone
      clone["type"] = type
      filter_matched(clone)
      yield clone
    end
  end

end

class LogStash::Outputs::MockStdout < LogStash::Outputs::Base

  config_name "mock_stdout"

  default :codec, "line"

  public
  def register
    @codec.on_event do |event, data|
      $stdout.write(data)
    end
  end

  def receive(event)
    return unless output?(event)
    return if event == LogStash::SHUTDOWN
    @codec.encode(event)
  end

end # class LogStash::Outputs::Stdout

# use a dummy NOOP input to test Inputs::Base
class LogStash::Inputs::NOOP < LogStash::Inputs::Base
  config_name "noop"
  milestone 2

  def register; end

end

# use a dummy NOOP filter to test Filters::Base
class LogStash::Filters::NOOP < LogStash::Filters::Base
  config_name "noop"
  milestone 2

  def register; end

  def filter(event)
    return unless filter?(event)
    filter_matched(event)
  end
end


# use a dummy NOOP output to test Outputs::Base
class LogStash::Outputs::NOOP < LogStash::Outputs::Base
  config_name "noop"
  milestone 2

  config :dummy_option, :validate => :string

  def register; end

  def receive(event)
    return output?(event)
  end
end
