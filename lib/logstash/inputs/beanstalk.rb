require "logstash/inputs/base"
require "logstash/namespace"

# Pull events from a beanstalk tube.
#
# TODO(sissel): Document where to learn more about beanstalk.
class LogStash::Inputs::Beanstalk < LogStash::Inputs::Base

  config_name "beanstalk"

  # The address of the beanstalk server
  config :host, :validate => :string, :required => true

  # The port of your beanstalk server
  config :port, :validate => :number, :default => 11300

  # The name of the beanstalk tube
  config :tube, :validate => :string, :required => true

  public
  def register
    require "beanstalk-client"
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

  public
  def teardown
    @beanstalk.close rescue nil
  end # def teardown
end # class LogStash::Inputs::Beanstalk
