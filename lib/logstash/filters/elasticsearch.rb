require "logstash/filters/base"
require "logstash/namespace"
require "logstash/util/fieldreference"

# Search elasticsearch for a previous log event and copy some fields from it
# into the current event.  Below is a complete example of how this filter might
# be used.  Whenever logstash receives an "end" event, it uses this elasticsearch
# filter to find the matching "start" event based on some operation identifier.
# Then it copies the @timestamp field from the "start" event into a new field on
# the "end" event.  Finally, using a combination of the "date" filter and the
# "ruby" filter, we calculate the time duration in hours between the two events.
#
#       if [type] == "end" {
#          elasticsearch {
#             hosts => ["es-server"]
#             query => "type:start AND operation:%{[opid]}"
#             fields => ["@timestamp", "started"]
#          }
#
#          date {
#             match => ["[started]", "ISO8601"]
#             target => "[started]"
#          }
#
#          ruby {
#             code => "event['duration_hrs'] = (event['@timestamp'] - event['started']) / 3600 rescue nil"
#          }
#       }
#
class LogStash::Filters::Elasticsearch < LogStash::Filters::Base
  config_name "elasticsearch"
  milestone 1

  # List of elasticsearch hosts to use for querying.
  config :hosts, :validate => :array

  # Elasticsearch query string
  config :query, :validate => :string

  # Comma-delimited list of <field>:<direction> pairs that define the sort order
  config :sort, :validate => :string, :default => "@timestamp:desc"

  # Hash of fields to copy from old event (found via elasticsearch) into new event
  config :fields, :validate => :hash, :default => {}

  public
  def register
    require "elasticsearch"

    @logger.info("New ElasticSearch filter", :hosts => @hosts)
    @client = Elasticsearch::Client.new hosts: @hosts
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    begin
      query_str = event.sprintf(@query)

      results = @client.search q: query_str, sort: @sort, size: 1

      @fields.each do |old, new|
        event[new] = results['hits']['hits'][0]['_source'][old]
      end

      filter_matched(event)
    rescue => e
      @logger.warn("Failed to query elasticsearch for previous event",
                   :query => query_str, :event => event, :error => e)
    end
  end # def filter
end # class LogStash::Filters::Elasticsearch
