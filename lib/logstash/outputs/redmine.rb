# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# The redmine output is used to create a ticket via the API redmine. 
#
# It send a POST request in a JSON format and use TOKEN authentication
# This output provide ssl connection method but does not check the certificate
#
#
# -- Exemple of use --
#  
#  output {
#    redmine {
#      url => "http://redmineserver.tld"
#      token => 'token'
#      project_id => 200
#      tracker_id => 1
#      status_id => 3
#      priority_id => 2
#      subject => "Error ... detected"
#    }
#  }


class LogStash::Outputs::Redmine < LogStash::Outputs::Base

  config_name "redmine"
  milestone 1

  # host of redmine app
  # required
  # value format : 'http://urlofredmine.tld' - Not add '/issues' at end
  config :url, :validate => :string, :required => true

  # http request ssl trigger
  # not required
  config :ssl, :validate => :boolean, :default => false 

  # redmine token user used for authentication
  # required
  config :token, :validate => :string, :required => true

  # redmine issue projet_id 
  # required 
  config :project_id, :validate => :number, :required => true

  # redmine issue tracker_id
  # required 
  config :tracker_id, :validate => :number, :required => true

  # redmine issue status_id
  # required 
  config :status_id, :validate => :number, :required => true 

  # redmine issue priority_id
  # required 
  config :priority_id, :validate => :number, :required => true

  # redmine issue subject
  # required 
  config :subject, :validate => :string, :default => "%{host}"
          
  # redmine issue description
  # required
  config :description, :validate => :string, :default => "%{message}"

  # redmine issue assigned_to
  # not required for post_issue
  config :assigned_to_id, :validate => :number, :default => nil
  
  # redmine issue parent_issue_id
  # not required for post_issue
  config :parent_issue_id, :validate => :number, :default => nil

  # redmine issue categorie_id
  # not required for post_issue
  config :categorie_id, :validate => :number, :default => nil

  # redmine issue fixed_version_id
  # not required for post_issue
  config :fixed_version_id, :validate => :number, :default => nil

  public
  def register

    require 'net/http'
    require 'uri'   

    # url form
    # TODO : Add a mecanism that verify and format this value
    @post_format = 'json'
    @formated_url = "#{@url}/issues.#{@post_format}"
    @uri = URI(@formated_url)
    @logger.debug("formated_uri:",:uri => @formated_url) 
  
    #http prepare
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @header = { 'Content-Type' => 'application/json', 'X-Redmine-Api-Key' => "#{@token}" } 
    @req = Net::HTTP::Post.new(@uri.path, @header)
    @logger.debug("request instancied with:", :uri_path => @uri.path, :header => @header )
    
    #ssl verify
    if @ssl == true 
      @logger.info("ssl use detected", :ssl => @ssl)
      @http.use_ssl = true
      # disable ssl certificate verification
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
    end

  end # def register


  public
  def receive(event)

    return unless output?(event)
    
    if event == LogStash::SHUTDOWN
      finished
      return
    end


    # interpolate parameters 
    description = event.sprintf(@description)
    subject = event.sprintf(@subject)

    # Create a hash that's used for make the post_http_request with required parameters
    @issue = Hash.new
    @issue = { "issue" => {
                     "project_id" => "#{@project_id}",
                     "tracker_id" => "#{@tracker_id}",
                     "priority_id" => "#{@priority_id}",
                     "status_id" => "#{@status_id}",
                     "subject" => "#{subject}",
                     "description" => "#{description}"
                     }
             } 

    # Add "not required" issue parameters in the issue hash
    @issue["issue"]["assigned_to_id"] = "#{@assigned_to_id}" if not @assigned_to_id.nil?
    @issue["issue"]["parent_issue_id"] = "#{@parent_issue_id}" if not @parent_issue_id.nil?    
    @issue["issue"]["category_id"] = "#{@category_id}" if not @category_id.nil?
    @issue["issue"]["fixed_version_id"] = "#{@fixed_version_id}" if not @fixed_version_id.nil?

    # change hash issue to json for the request
    @req.body = @issue.to_json
    
    # send the post_http_request "req" 
    @logger.info("Sending request to redmine :", :host => @formated_url, :body => @req.body)
    begin 
      @http.request(@req)
    rescue => e
      @logger.warn("Skipping redmine output; error during request post", "error" => $!, "missed_event" => event)
    end #begin

  end # def receive
end
