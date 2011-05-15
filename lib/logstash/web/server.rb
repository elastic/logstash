#!/usr/bin/env ruby
# I don't want folks to have to learn to use yet another tool (rackup)
# just to launch logstash-web. So let's work like a standard ruby
# executable.
##rackup -Ilib:../lib -s thin

$:.unshift("%s/../lib" % File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__))

require "logstash/search/elasticsearch"
require "logstash/search/query"
require "logstash/namespace"
require "logstash/web/helpers/require_param"
require "json" # gem json
require "rack" # gem rack
require "mizuno" # gem mizuno
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

  #register Sinatra::Async
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

  def initialize(settings={})
    super
    # TODO(sissel): Make this better.
    backend_url = URI.parse(settings.backend_url)

    case backend_url.scheme 
      when "elasticsearch"
        # if host is nil, it will 
        # TODO(sissel): Support 'cluster' name?
        cluster_name = (backend_url.path != "/" ? backend_url.path[1..-1] : nil)
        @backend = LogStash::Search::ElasticSearch.new(
          :host => backend_url.host,
          :port => backend_url.port,
          :cluster => cluster_name
        )
      when "twitter"
        require "logstash/search/twitter"
        @backend = LogStash::Search::Twitter.new(
          :host => backend_url.host,
          :port => backend_url.port
        )
    end # backend_url.scheme
  end # def initialize
 
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

require "optparse"
Settings = Struct.new(:daemonize, :logfile, :address, :port, :backend_url)
settings = Settings.new

settings.address = "0.0.0.0"
settings.port = 9292
settings.backend_url = "elasticsearch:///"

progname = File.basename($0)

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{progname} [options]"

  opts.on("-d", "--daemonize", "Daemonize (default is run in foreground).") do
    settings.daemonize = true
  end

  opts.on("-l", "--log FILE", "Log to a given path. Default is stdout.") do |path|
    settings.logfile = path
  end

  opts.on("-a", "--address ADDRESS", "Address on which to start webserver. Default is 0.0.0.0.") do |address|
    settings.address = address
  end

  opts.on("-p", "--port PORT", "Port on which to start webserver. Default is 9292.") do |port|
    settings.port = port.to_i
  end

  opts.on("-b", "--backend URL",
          "The backend URL to use. Default is elasticserach:/// (assumes " \
          "multicast discovery); You can specify " \
          "elasticsearch://[host][:port]/[clustername]") do |url|
    settings.backend_url = url
  end
end

opts.parse!

if settings.daemonize
  $stderr.puts "Daemonizing is not supported. (JRuby has no 'fork')"
  exit(1)
  #if Process.fork == nil
    #Process.setsid
  #else
    #exit(0)
  #end
end

if settings.logfile
  logfile = File.open(settings.logfile, "w")
  STDOUT.reopen(logfile)
  STDERR.reopen(logfile)
elsif settings.daemonize
  # Write to /dev/null if
  devnull = File.open("/dev/null", "w")
  STDOUT.reopen(devnull)
  STDERR.reopen(devnull)
end

Mizuno::HttpServer.run(
  LogStash::Web::Server.new(settings),
  :port => settings.port, :host => settings.address)
