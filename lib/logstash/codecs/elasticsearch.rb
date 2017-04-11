# encoding: utf-8
require "logstash/codecs/base"
require "logstash/codecs/line"
require "json"

# Elasticsearch bulk codec
class LogStash::Codecs::ElasticSearch < LogStash::Codecs::Base
  config_name "elasticsearch"

  milestone 1

  # The index to write events to. This can be dynamic using the %{foo} syntax.
  # The default value will partition your indeces by day so you can more easily
  # delete old data or only search specific date ranges.
  config :index, :validate => :string, :default => "logstash-%{+YYYY.MM.dd}"

  # The index type to write events to. Generally you should try to write only
  # similar events to the same 'type'. String expansion '%{foo}' works here.
  config :index_type, :validate => :string, :default => "%{type}"

  # The document ID for the index. Useful for overwriting existing entries in
  # elasticsearch with the same ID.
  config :document_id, :validate => :string, :default => nil

  # Should the bulk API call include the index name? If your Elasticsearch
  # cluster has rest.action.multi.allow_explicit_index set to false and
  # you're indexing over HTTP(S) this should be set to false too
  config :explicit_index, :validate => :boolean, :default => true

  public
  def initialize(params={})
    super(params)
    @lines = LogStash::Codecs::Line.new
  end # def initialize

  public
  def decode(data)

    # The ElasticSearch bulk API commands
    keys = %w[index delete create update doc]

    @lines.decode(data) do |event|
      begin
        json = JSON.parse(event["message"])

        # Skip any line that is a bulk API command
        if json.keys.length == 1 and (json.keys & keys).any?
          @logger.debug("Skipping bulk API command", :command => json)
          next
        end

        yield LogStash::Event.new(json)
      rescue JSON::ParserError => e
        @logger.warn("Not JSON", :error => e, :event => event)
      end
    end
  end # def decode

  public
  def encode(data)
    # Will this ever be fed non-event data?
    if !data.is_a? LogStash::Event
      @logger.warn("Not an event", :data => data)
      return
    end

    header = { "index" => { "_type" => data.sprintf(@index_type) } }
    if @explicit_index
      header["index"]["_index"] = data.sprintf(@index)
    end
    if !@document_id.nil?
      header["index"]["_id"] = data.sprintf(@document_id)
    end

    @on_event.call(header.to_json + "\n" + data.to_json + "\n")
  end # def encode
end # class LogStash::Codecs::Elasticsearch
