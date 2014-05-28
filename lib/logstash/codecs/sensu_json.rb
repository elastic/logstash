# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "json"


# This codec may be used to encode (via outputs)
# full JSON messages destined for Sensu,
# either directly through a socket (port 3030 on a client)
# or to the rabbitmq the client would normally talk to.
#
# Encoding will emit a single JSON string ending in a '\n'
class LogStash::Codecs::SensuJSON < LogStash::Codecs::Base
  config_name "sensu_json"

  milestone 0

  # Copied from codec json_lines :
  #
  # The character encoding used in this codec. Examples include "UTF-8" and
  # "CP1252"
  #
  # JSON requires valid UTF-8 strings, but in some cases, software that
  # emits JSON does so in another encoding (nxlog, for example). In
  # weird cases like this, you can set the charset setting to the
  # actual encoding of the text and logstash will convert it for you.
  #
  # For nxlog users, you'll want to set this to "CP1252"
  config :charset, :validate => ::Encoding.name_list, :default => "UTF-8"

  public
  def initialize(params={})
    super(params)
    @lines = LogStash::Codecs::Line.new
    @lines.charset = @charset

    @@default_check_values = {

        # these three symbols required to pass sensu check validation
        :name => "logstash_watchdog_detected_error_in_application_log",
        :output => "Logstash detected a monitored error message: NOT OK\n",
        :status => 1,   # default is error

        # "description of check here"
        :notification => "Logstash watchdog detected a error in product log"

        # some of these are created by the logstash processor on the client side:

        # :command => "command line here",
        # :subscribers:
        # :standalone => true,
        # :interval => 10,
        # :occurrences  => 40,
        # :handlers => ["default"],
        # :issued => 1398365245,
        # :executed => 1398365245,
        # :duration => 0.584
    }
  end

  public
  def decode(data)
    raise "Not implemented"
  end # def decode

  public
  def encode(data)
    incoming_data = data.to_hash

    # if not present, add default values into this event

    @@default_check_values.keys.each do |key|
      incoming_data[key] = @@default_check_values[key] unless incoming_data.has_key? key
    end

    @on_event.call(incoming_data.to_json)
  end # def encode


end

