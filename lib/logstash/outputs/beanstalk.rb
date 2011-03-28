require "logstash/outputs/base"
require "logstash/namespace"
require "beanstalk-client"

class LogStash::Outputs::Beanstalk < LogStash::Outputs::Base

  config_name "beanstalk"
  config :host, :validate => :string, :required => true
  config :port, :validate => :number
  config :tube, :validate => :string, :required => true
  config :priority, :validate => :number
  config :delay, :validate => :number
  config :ttr, :validate => :number

  public
  def initialize(params)
    super

    @port ||= 11300
    @priority ||= 65536
    @delay ||= 0
    @ttr ||= 300
  end

  public
  def register
    # TODO(petef): support pools of beanstalkd servers
    # TODO(petef): check for errors
    @beanstalk = Beanstalk::Pool.new(["#{@host}:#{@port}"])
    @beanstalk.use(@tube)
  end # def register

  public
  def receive(event)
    @beanstalk.put(event.to_json, @priority, @delay, @ttr)
  end # def register
end # class LogStash::Outputs::Beanstalk
