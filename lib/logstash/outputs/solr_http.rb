require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"
require "rubygems"
require "uuidtools"

# This output lets you index&store your logs in Solr. If you want to get
# started quickly you should use version 4.4 or above in schemaless mode,
# which will try and guess your fields automatically. To turn that on,
# you can use the example included in the Solr archive:
#
#     tar zxf solr-4.4.0.tgz
#     cd example
#     mv solr solr_ #back up the existing sample conf
#     cp -r example-schemaless/solr/ .  #put the schemaless conf in place
#     java -jar start.jar   #start Solr
#
# You can learn more about Solr at <https://lucene.apache.org/solr/>

class LogStash::Outputs::SolrHTTP < LogStash::Outputs::Base
  include Stud::Buffer

  config_name "solr_http"

  milestone 1

  # URL used to connect to Solr
  config :solr_url, :validate => :string, :default => "http://localhost:8983/solr"

  # Number of events to queue up before writing to Solr
  config :flush_size, :validate => :number, :default => 100

  # Amount of time since the last flush before a flush is done even if
  # the number of buffered events is smaller than flush_size
  config :idle_flush_time, :validate => :number, :default => 1

  # Solr document ID for events. You'd typically have a variable here, like
  # '%{foo}' so you can assign your own IDs
  config :document_id, :validate => :string, :default => nil

  public
  def register
    require "rsolr"
    @solr = RSolr.connect :url => @solr_url
    buffer_initialize(
      :max_items => @flush_size,
      :max_interval => @idle_flush_time,
      :logger => @logger
    )
  end #def register

  public
  def receive(event)
    return unless output?(event)
    buffer_receive(event)
  end #def receive

  public
  def flush(events, teardown=false)
    documents = []  #this is the array of hashes that we push to Solr as documents

    events.each do |event|
        document = event.to_hash()
        document["@timestamp"] = document["@timestamp"].iso8601 #make the timestamp ISO
        if @document_id.nil?
          document ["id"] = UUIDTools::UUID.random_create    #add a unique ID
        else
          document ["id"] = event.sprintf(@document_id)      #or use the one provided
        end
        documents.push(document)
    end

    @solr.add(documents)
    rescue Exception => e
      @logger.warn("An error occurred while indexing: #{e.message}")
  end #def flush
end #class LogStash::Outputs::SolrHTTP
