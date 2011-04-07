require "logstash/outputs/base"
require "logstash/namespace"
require "beanstalk-client"

class LogStash::Outputs::Beanstalk < LogStash::Outputs::Base

  config_name "beanstalk"

  # The address of the beanstalk server
  config :host, :validate => :string, :required => true

  # The port of your beanstalk server
  config :port, :validate => :number, :default => 11300

  # The name of the beanstalk tube
  config :tube, :validate => :string, :required => true

  # The message priority (see beanstalk docs)
  config :priority, :validate => :number, :default => 65536

  # The message delay (see beanstalk docs)
  config :delay, :validate => :number, :default => 0

  # TODO(sissel): Document this
  # See beanstalk documentation
  config :ttr, :validate => :number, :default => 300

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
