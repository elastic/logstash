require "logstash/outputs/base"
require "logstash/namespace"
require "stud/buffer"

# Send events to a Flapjack instance.
#
# If you're using a standalone Flapjack, this is all the configuration you need:
#
#  output {
#    flapjack {
#    }
#  }
#
# There are also a bunch of options that you can use:
#
#  output {
#    flapjack {
#      host     => '10.3.26.2',
#      port     => 6830
#      password => 'secret'
#      db       => 13
#      timeout  => 10
#      severity_level => 'ok'
#    }
#  }
#
#  Within your filters, make sure you pass through the following fields:
#
#   flapjack_check, flapjack_entity, summary
#
#  For example, here is a grok filter:
#
#   filter {
#     grok {
#       type      => "mac-syslog"
#       pattern   => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{HOSTNAME:syslog_hostname} %{GREEDYDATA:summary}"
#       add_field => [ "flapjack_check", "log", "flapjack_entity", "%{syslog_hostname}" ]
#     }
#
#     date {
#       type  => "mac-syslog"
#       match => ['syslog_timestamp', "MMM dd HH:mm:ss"]
#     }
#   }
#
# The Flapjack plugin is based on the existing Redis and Nagios plugins for Logstash.
#
class LogStash::Outputs::Flapjack < LogStash::Outputs::Base

  include Stud::Buffer

  config_name "flapjack"
  plugin_status "beta"

  # The hostname(s) of your Redis server(s). Ports may be specified on any
  # hostname, which will override the global port config.
  #
  # For example:
  #
  #     "127.0.0.1"
  #     ["127.0.0.1", "127.0.0.2"]
  #     ["127.0.0.1:6380", "127.0.0.1"]
  config :host, :validate => :array, :default => ["127.0.0.1"]

  # Shuffle the host list during logstash startup.
  config :shuffle_hosts, :validate => :boolean, :default => true

  # The default port to connect on. Can be overridden on any hostname.
  config :port, :validate => :number, :default => 6379

  # The Redis database number.
  #
  # These are the Redis database numbers used by Flapjack:
  #
  #   6  => quickstart
  #   13 => development
  #   14 => test
  #   15 => staging
  #   12 => production
  #   14 => profile
  #
  config :db, :validate => :number, :default => 6

  # Redis initial connection timeout in seconds.
  config :timeout, :validate => :number, :default => 5

  # Password to authenticate with Redis.  There is no authentication by default.
  config :password, :validate => :password

  # The check sevirity level. Should be one of ok, warning, critical, unknown.
  config :severity_level, :validate => %w(ok warning critical unknown), :default => 'critical'

  def register
    require 'redis'

    @key = 'events'
    @redis = nil

    if @shuffle_hosts
      @host.shuffle!
    end
    @host_idx = 0
  end # def register

  def receive(event)
    return unless output?(event)

    # Validate that the event has the required fields, and drop on the floor
    # if it doesn't.
    if not event['flapjack_entity']
      @logger.warn('Skipping Flapjack output; flapjack_entity field is missing',
                   :missed_event => event)
      return
    end

    if not event['flapjack_check']
      @logger.warn('Skipping Flapjack output; flapjack_check field is missing',
                   'missed_event' => event)
      return
    end

    state = @severity_level || event['severity_level']

    flapjack_event = {
      'entity'  => event['flapjack_entity'].first,
      'check'   => event['flapjack_check'].first,
      'type'    => 'service',
      'state'   => state,
      'time'    => event.unix_timestamp,
      'summary' => event['summary'].first,
    }

    event_key_and_payload = [event.sprintf(@key), flapjack_event.to_json]

    @logger.warn("sent to redis", :event => flapjack_event)

    begin
      @redis ||= connect
      @redis.rpush(*event_key_and_payload)
    rescue => e
      @logger.warn("Failed to send event to redis", :event => event,
                   :identity => identity, :exception => e,
                   :backtrace => e.backtrace)
      sleep 1
      @redis = nil
      retry
    end
  end # def receive

  private
  def connect
    @current_host, @current_port = @host[@host_idx].split(':')
    @host_idx = @host_idx + 1 >= @host.length ? 0 : @host_idx + 1

    if not @current_port
      @current_port = @port
    end

    params = {
      :host => @current_host,
      :port => @current_port,
      :timeout => @timeout,
      :db => @db
    }
    @logger.debug(params)

    if @password
      params[:password] = @password.value
    end

    Redis.new(params)
  end # def connect

  # A string used to identify a redis instance in log messages
  def identity
    @name || "redis://#{@password}@#{@current_host}:#{@current_port}/#{@db} list:#{@key}"
  end

end
