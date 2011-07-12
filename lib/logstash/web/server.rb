#!/usr/bin/env ruby
# I don't want folks to have to learn to use yet another tool (rackup)
# just to launch logstash-web. So let's work like a standard ruby
# library.


$:.unshift("%s/../lib" % File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__))

require "json" # gem json
require "logstash/namespace"
require "logstash/search/elasticsearch"
require "logstash/search/query"
require "logstash/web/controllers/api_v1"
require "logstash/web/controllers/search"
require "logstash/web/controllers/static_files"
require "logstash/web/helpers/require_param"
require "optparse"
require "rack" # gem rack
require "sinatra/base" # gem sinatra

class LogStash::Web::Server < Sinatra::Base

  mime_type :html, "text/html"
  mime_type :txt, "text/plain"
  mime_type :json, "text/plain" # so browsers don't "download" when viewed
  mime_type :javascript, "application/javascript"
  mime_type :gif, "image/gif"
  mime_type :jpg, "image/jpeg"
  mime_type :png, "image/png"

  require "logstash/web/controllers/api_v1"
  require "logstash/web/controllers/static_files"
  require "logstash/web/controllers/search"

  helpers Sinatra::RequireParam # logstash/web/helpers/require_param

  set :haml, :format => :html5
  set :logging, true
  set :views, "#{File.dirname(__FILE__)}/views"

  use Rack::CommonLogger
  use Rack::ShowExceptions
  
  # We could do 'use' here, but 'use' is for middleware and it seems difficult
  # (intentionally?) to share between middlewares. We'd need to share the
  # instances variables like @backend, etc.
  #
  # Load anything in controllers/
  #Dir.glob(File.join(File.dirname(__FILE__), "controllers", "**", "*")).each do |path|
    #puts "Loading #{path}"
    ## TODO(sissel): This is pretty shitty.
    #eval(File.new(path).read, binding, path)
  #end
  #

  def initialize(settings)
    super()

    # TODO(sissel): Make this better.
    backend_url = URI.parse(settings.backend_url)

    case backend_url.scheme 
      when "elasticsearch"
        # if host is nil, it will 
        # TODO(sissel): Support 'cluster' name?
        cluster_name = (backend_url.path != "/" ? backend_url.path[1..-1] : nil)
        options = {
          :host => backend_url.host,
          :port => backend_url.port,
          :cluster => cluster_name,
          :bind_host => settings.bind_host,
        }
        query = backend_url.query
        if !(query.nil? or query.empty?)
          if !%w(local node).include?(query)
            raise "Invalid elasticsearch node type '#{query}' - expected " \
              "'local' or 'node'"
          end
          options[:type] = query.to_sym
        end

        #p :web_es_config => options
        @backend = LogStash::Search::ElasticSearch.new(options)
      when "twitter"
        require "logstash/search/twitter"
        @backend = LogStash::Search::Twitter.new(
          :host => backend_url.host,
          :port => backend_url.port
        )
    end # backend_url.scheme
  end

  get '/style.css' do
    headers "Content-Type" => "text/css; charset=utf8"
    body sass :style
  end # /style.css

  get '/' do
    redirect "/search"
  end # '/'

  get '/*' do
    status 404 if @error
    body "Invalid path."
  end # get /*
end # class LogStash::Web::Server
