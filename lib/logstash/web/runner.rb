require "logstash/namespace"
require "mizuno" # gem mizuno

class LogStash::Web::Runner
  Settings = Struct.new(:logfile, :address, :port,
                        :backend_url, :bind_host)

  public
  def run(args)
    jarpath = File.join(File.dirname(__FILE__), "..", "..", "..", "vendor", 
                        "**", "*.jar")
    #p :jarpath => jarpath
    Dir[jarpath].each do |jar|
      #p :jar => jar
      require jar
    end

    require "logstash/web/server"

    settings = Settings.new

    settings.address = "0.0.0.0"
    settings.port = 9292
    settings.backend_url = "elasticsearch:///"

    progname = File.basename($0)

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{progname} [options]"

      opts.on("-l", "--log FILE", "Log to a given path. Default is stdout.") do |path|
        settings.logfile = path
      end

      opts.on("-a", "--address ADDRESS", "Address on which to start webserver. Default is 0.0.0.0.") do |address|
        settings.address = address
      end

      opts.on("-p", "--port PORT", "Port on which to start webserver. Default is 9292.") do |port|
        settings.port = port.to_i
      end

      opts.on("-B", "--elasticsearch-bind-host ADDRESS", "Address on which to bind elastic search node.") do |addr|
        settings.bind_host = addr
      end

      opts.on("-b", "--backend URL",
              "The backend URL to use. Default is elasticserach:/// (assumes " \
              "multicast discovery); You can specify " \
              "elasticsearch://[host][:port]/[clustername]") do |url|
        settings.backend_url = url
      end
    end

    args = opts.parse(args)

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

    @thread = Thread.new do
      Mizuno::HttpServer.run(
        LogStash::Web::Server.new(settings),
        :port => settings.port,
        :host => settings.address)
    end

    return args
  end # def run

  public
  def wait
    @thread.join
    return 0
  end # def wait
end # class LogStash::Web::Runner
 
