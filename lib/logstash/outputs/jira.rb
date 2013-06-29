# Origin https://groups.google.com/forum/#!msg/logstash-users/exgrB4iQ-mw/R34apku5nXsJ
# From https://gist.github.com/electrical/4660061e8fff11cdcf37#file-jira-rb                                                               
# From https://botbot.me/freenode/logstash/msg/4169496/ 

require "logstash/outputs/base"
require "logstash/namespace"
require "uri"
# TODO(sissel): Move to something that performs better than net/http
require "net/http"
require "net/https"

# Ugly monkey patch to get around <http://jira.codehaus.org/browse/JRUBY-5529>
Net::BufferedIO.class_eval do
    BUFSIZE = 1024 * 16

    def rbuf_fill
      timeout(@read_timeout) {
        @rbuf << @io.sysread(BUFSIZE)
      }
    end
end


#
# This is most useful so you can use logstash to parse and structure
# your logs and ship structured, json events to JIRA
#
# To use this, you'll need to use a JIRA input with type 'http'
# and 'json logging' enabled.
class LogStash::Outputs::Jira < LogStash::Outputs::Base
  config_name "jira"
  milestone 2

  # The hostname to send logs to. This should target your JIRA server 
  # and has to have the REST interface enabled
  config :host, :validate => :string, :default => ""

  # The RestAPI key
  config :key, :validate => :string, :required => true

  # Should the log action be sent over https instead of plain http
  config :proto, :validate => :string, :default => "http"

  # Proxy Host
  config :proxy_host, :validate => :string

  # Proxy Port
  config :proxy_port, :validate => :number

  # Proxy Username
  config :proxy_user, :validate => :string

  # Proxy Password
  config :proxy_password, :validate => :password, :default => ""
  
  # Ticket creation method
  config :method, :validate => :string, :default => 'new'
  
  # Search fields; When in 'append' method. search for a ticket that has these fields and data.
  config :searchfields, :validate => :hash
  
  # createfields; Add data to these fields at initial creation
  config :createfields, :validate => :hash
  
  # appendfields; Update data in these fields when appending data to an existing ticket
  config :appendfields, :validate => :hash
  
  # Comment; Add this in the comment field ( is for new and append method the same )
  config :comment, :validate => :string


  public
  def register
    # nothing to do
  end

  public
  def receive(event)
    return unless output?(event)

    if event == LogStash::SHUTDOWN
      finished
      return
    end

    # Send the event over http.
# curl -D- -u fred:fred -X POST --data {see below} -H "Content-Type: application/json" http://localhost:8090/rest/api/2/issue/
# https://developer.atlassian.com/display/JIRADEV/JIRA+REST+API+Example+-+Create+Issue#JIRARESTAPIExample-CreateIssue-Request.3
    url = URI.parse("#{@proto}://#{@host}/rest/api/2/issue")
    @logger.info("JIRA Rest Url", :url => url)
    http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_password.value).new(url.host, url.port)
    if url.scheme == 'https'
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Post.new(url.path)
    request.template = {
    "fields": {
       "project":
       { 
          "key": "TEST"
       },
       "summary": "Always do right. This will gratify some people and astonish the REST.",
       "description": "Creating an issue while setting custom field values",
       "issuetype": {
          "name": "Bug"
       },       
   }
   }
#       "customfield_11050" : {"Value that we're putting into a Free Text Field."}       
#    request.body = event.to_json
    request.body = request.template
    response = http.request(request)
    if response.is_a?(Net::HTTPSuccess)
      @logger.info("Event send to Jira OK!")
    else
      @logger.warn("HTTP error", :error => response.error!)
    end
  end # def receive
end # class LogStash::Outputs::Jira
