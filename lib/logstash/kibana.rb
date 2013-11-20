# encoding: utf-8
require "rack/handler/ftw" # gem ftw
require "ftw" # gem ftw
require "sinatra/base" # gem sinatra
require "optparse"
require "mime/types"

class Rack::Handler::FTW
  alias_method :handle_connection_, :handle_connection
  def handle_connection(connection)
    #require "pry"; binding.pry
    return handle_connection_(connection)
  end
end

module LogStash::Kibana
  class App < Sinatra::Base
    set :logging, true

    use Rack::CommonLogger
    use Rack::ShowExceptions

    get "/" do
      redirect "index.html"
    end
    
    # Sinatra has problems serving static files from 
    # jar files, so let's hack this by hand.
    #set :public, "#{File.dirname(__FILE__)}/public"
    get "/config.js" do static_file end
    get "/index.html" do static_file end
    get "/app/*" do static_file end
    get "/css/*" do static_file end
    get "/font/*" do static_file end
    get "/img/*" do static_file end
    get "/vendor/*" do static_file end

    def static_file
      # request.path_info is the full path of the request.
      docroot =  File.expand_path(File.join(File.dirname(__FILE__), "../../vendor/kibana"))
      path = File.join(docroot, *request.path_info.split("/"))
      if File.exists?(path)
        ext = path.split(".").last
        content_type MIME::Types.type_for(ext).first.to_s
        body File.new(path, "r").read
      else
        status 404
        content_type "text/plain"
        body "File not found: #{path}"
      end
    end # def static_file
  end # class App

  class Runner
    Settings = Struct.new(:logfile, :address, :port, :backend)

    public
    def run(args)
      settings = Settings.new
      settings.address = "0.0.0.0"
      settings.port = 9292
      settings.backend = "localhost"

      progname = File.basename($0)

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{progname} [options]"
        opts.on("-a", "--address ADDRESS", "Address on which to start webserver. Default is 0.0.0.0.") do |address|
          settings.address = address
        end

        opts.on("-p", "--port PORT", "Port on which to start webserver. Default is 9292.") do |port|
          settings.port = port.to_i
        end

        #opts.on("-b", "--backend host",
                #"The backend host to use. Default is 'localhost'") do |host|
          #settings.backend = host
        #end
      end

      begin
        args = opts.parse(args)
      rescue SystemExit
        # if you ask for --help, optparse will exit.
        # capture it and return normally
        return []
      end

      @thread = Thread.new do
        Cabin::Channel.get.info("Starting web server", :settings => settings)
        ftw = Rack::Handler::FTW.new(LogStash::Kibana::App.new,
                               :Host => settings.address,
                               :Port => settings.port)
        trap_id = Stud::trap("INT") do
          puts "Stopping web..."
          ftw.stop rescue nil
          raise SystemExit
        end

        ftw.run
      end

      return args
    end # def run

    public
    def wait
      @thread.join if @thread
      return 0
    end # def wait
  end
end
