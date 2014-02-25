# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Redmine < LogStash::Outputs::Base

  config_name "Redmine"
  milestone 1

  # url of redmine app
  config :url, :validate => :string, :required => true

  # request format, json or xml
  config :post_format, :validate => ["json", "xml"], :default => "json"

  # redmine token user
  config :token, :validate => :string, :required => true

  # redmine issue projet_id
  config :project_id, :validate => :number, :required => true

  # redmine issue tracker_id 
  config :tracker_id, :validate => :number, :required => true

  # redmine issue status_id
  config :status_id, :validate => :number, :default => 1 

  # redmine issue priority_id
  config :priority_id, :validate => :number, :required => true

  # redmine issue assigned_to
  config :assigned_to_id, :validate => :number

  # redmine issue subject
  config :subject, :validate => :string, :required => true
          
  # redmine issue description
  config :description, :validate => :string, :required => true

  public
  def register
    require 'net/http'
    require 'uri'   

    # url form
    @formated_url = "#{@url}/issues.#{@post_format}"
    @uri = URI(@formated_url)

    #http prepare
    @http = Net::HTTP.new(@uri.host, @uri.port)
    @header = { 'Content-Type' => 'application/json', 'X-Redmine-Api-Key' => "#{@token}" } 
    @req = Net::HTTP::Post.new(@uri.path, @header)

  end # def register

  public
  def receive(event)
    return unless output?(event)
    
    require 'rubygems'
    require 'json'

    # Create body
    @issue = { "issue" => {
                     "project_id" => "#{@project_id}",
                     "tracker_id" => "#{@tracker_id}",
                     "priority_id" => "#{@priority_id}",
                     "status_id" => "#{@status_id}",
                     "subject" => "#{@subject}",
                     "description" => "#{@description}"
                     }
            } 

    # add not required issue params
    @issue["issue"]["assigned_to"] = "#{@assigned_to}" if !@assigned_to.nil?
 
    
    # Set request.body in relation with post_format value
    if @post_format == "json"
      @req.body = @issue.to_json
    else
    # TODO : Make to_xml like ...    
    end
    
    # send http request
    @http.request(@req)

  end # def receive

end

