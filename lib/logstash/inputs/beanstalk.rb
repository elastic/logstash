require "logstash/inputs/base"
require "em-jack"

class LogStash::Inputs::Beanstalk < LogStash::Inputs::Base
  def initialize(url, type, config={}, &block)
    super

    if @url.path == "" or @url.path == "/"
      raise "must specify a tube for beanstalk output"
    end
  end

  def register
    tube = @url.path[1..-1] # Skip leading '/'
    port = @url.port || 11300
    @beanstalk = EMJack::Connection.new(:host => @url.host,
                                        :port => port,
                                        :tube => tube)
    @beanstalk.each_job do |job|
      begin
        event = LogStash::Event.from_json(job.body)
        receive(event)
        @beanstalk.delete(job)
      rescue => e
        @logger.warn(["Trouble parsing beanstalk job",
                     {:error => e.message, :body => job.body,
                      :backtrace => e.backtrace}])
        @beanstalk.bury(job, 0)
      end
    end # @beanstalk.each_job
  end # def register
end # class LogStash::Inputs::Beanstalk
