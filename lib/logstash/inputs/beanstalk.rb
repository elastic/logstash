require "em-jack"
require "logstash/inputs/base"
require "logstash/namespace"

class LogStash::Inputs::Beanstalk < LogStash::Inputs::Base

  config_name "beanstalk"
  config :tube => nil   # TODO(sissel): needs validation?

  public
  def initialize(params)
    super
    raise "issue/17: needs refactor to support configfile"

    if @url.path == "" or @url.path == "/"
      raise "must specify a tube for beanstalk output"
    end
  end # def initialize

  public
  def register
    tube = @url.path[1..-1] # Skip leading '/'
    port = @url.port || 11300
    @beanstalk = EMJack::Connection.new(:host => @url.host,
                                        :port => port,
                                        :tube => tube)
    @beanstalk.each_job do |job|
      begin
        event = LogStash::Event.from_json(job.body)
      rescue => e
        @logger.warn(["Trouble parsing beanstalk job",
                     {:error => e.message, :body => job.body,
                      :backtrace => e.backtrace}])
        @beanstalk.bury(job, 0)
      end

      receive(event)
      @beanstalk.delete(job)
    end # @beanstalk.each_job
  end # def register
end # class LogStash::Inputs::Beanstalk
