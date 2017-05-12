require 'elasticsearch'
require_relative './helpers'
require_relative '../framework/helpers'

class ElasticsearchService < Service
  def initialize(settings)
    super("elasticsearch", settings)
    @version = ENV["ES_VERSION"] || "5.0.1"
    @port = 9200
  end

  def get_client
    Elasticsearch::Client.new(:hosts => "localhost:#{@port}")
  end

  def do_setup
    unless Dir.exists? @home
      url = "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-#{@version}.tar.gz"
      target_name = "elasticsearch.tar.gz"
      file = download(url, @install_dir, target_name)
      untgz(file, @home, strip_path: 1)
      File.delete(file)
    end
    self.do_start
  end

  def do_start (args = [])
    cmd = [File.join(@home, 'bin', 'elasticsearch')]
    cmd += args
    puts "Starting Elasticsearch with #{cmd.join(" ")}"
    @process = BackgroundProcess.new(cmd).start

    puts "Waiting for Elasticsearch to respond at port #{@port}..."
    wait_for_port(@port, 120)
    if is_port_open? @port
      puts "Elasticsearch is Up !"
    else
      puts "Elasticsearch is unresponsive at port #{@port}"
    end
  end

  def do_stop
    @process.stop
  end

  def do_teardown
    self.do_stop
  end

end
