require "logstash/inputs/base"
require "logstash/namespace"
require "beanstalk-client"

class LogStash::Inputs::Beanstalk < LogStash::Inputs::Base

  config_name "beanstalk"
  config :host, :validate => :string, :required => true
  config :port, :validate => :number
  config :tube, :validate => :string, :required => true

  public
  def initialize(params)
    super

    @port ||= 11300
  end # def initialize

  public
  def register
    # TODO(petef): support pools of beanstalkd servers
    # TODO(petef): check for errors
    @beanstalk = Beanstalk::Pool.new(["#{@host}:#{@port}"])
    @beanstalk.watch(@tube)
  end # def register

  public
  def run(output_queue)
    loop do
      job = @beanstalk.reserve
      begin
        event = LogStash::Event.from_json(job.body)
      rescue => e
        @logger.warn(["Trouble parsing beanstalk job",
                     {:error => e.message, :body => job.body,
                      :backtrace => e.backtrace}])
        job.bury(job, 0)
      end
      output_queue << event
      job.delete
    end
  end # def run
end # class LogStash::Inputs::Beanstalk
