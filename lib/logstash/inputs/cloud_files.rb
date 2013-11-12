require 'fog'
require 'stringio'
require 'zlib'
require 'logstash/inputs/base'
require 'logstash/namespace'

class LogStash::Inputs::CloudFiles < LogStash::Inputs::Base
  milestone 1
  config_name 'cloud_files'

  default :codec, 'plain'

  config :username, :validate => :string, :required => true
  config :api_key, :validate => :string, :required => true
  config :region, :validate => :string, :required => true
  config :container, :validate => :string, :required => true
  config :interval, :validate => :number, :default => 60
  config :sincedb_path, :validate => :string, :required => true

  def register
    @api = Fog::Storage.new(:provider => 'Rackspace', :rackspace_username => @username, :rackspace_api_key => @api_key, :rackspace_region => @region)
  end

  def run(queue)
    loop do
      process_log_files(queue)
      sleep(@interval)
    end

    finished
  end

  private

  def process_log_files(queue)
    last_read = sincedb_read

    container = @api.directories.get(@container)
    container.files.each do |file|
      process_file(queue, file) if file.last_modified > last_read
    end
  end

  def process_file(queue, file)
    log_stream = StringIO.new(file.body)
    reader = Zlib::GzipReader.new(log_stream)
    reader.each_line { |l| process_line(queue, l) }

    sincedb_write(file.last_modified)
  end

  def process_line(queue, line)
    @codec.decode(line) do |event|
      decorate(event)
      queue << event
    end
  end

  def sincedb_read
    if File.exists?(@sincedb_path)
      since = Time.parse(File.read(@sincedb_path))
    else
      since = Time.new(0)
    end

    since
  end

  def sincedb_write(since)
    File.open(@sincedb_path, 'w') { |f| f.write(since.to_s) }
  end
end
