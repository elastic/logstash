require "logstash/codecs/base"
require "logstash/codecs/line"

class LogStash::Codecs::EDNLines < LogStash::Codecs::Base
  config_name "edn_lines"

  milestone 1

  def register
    require "edn"
  end

  public
  def initialize(params={})
    super(params)
    @lines = LogStash::Codecs::Line.new
  end

  public
  def decode(data)
    @lines.decode(data) do |event|
      begin
        yield LogStash::Event.new(EDN.read(event["message"]))
      rescue => e
        @logger.info("EDN parse failure. Falling back to plain-text", :error => e, :data => data)
        yield LogStash::Event.new("message" => data)
      end
    end
  end

  public
  def encode(data)
    @on_event.call(data.to_hash.to_edn + "\n")
  end

end
