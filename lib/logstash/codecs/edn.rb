require "logstash/codecs/base"
require "logstash/codecs/line"

class LogStash::Codecs::EDN < LogStash::Codecs::Base
  config_name "edn"

  milestone 1

  def register
    require "edn"
  end

  public
  def decode(data)
    begin
      yield LogStash::Event.new(EDN.read(data))
    rescue
      @logger.info("EDN parse failure. Falling back to plain-text", :error => e, :data => data)
      yield LogStash::Event.new("message" => data)
    end
  end

  public
  def encode(data)
    @on_event.call(data.to_hash.to_edn)
  end

end
