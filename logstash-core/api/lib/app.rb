# encoding: utf-8
require "cabin"
require "logstash/json"
require "app_helpers"
require "app/service"
require "app/command_factory"

module LogStash::Api
  class BaseApp < ::Sinatra::Application

    attr_reader :factory

    if settings.environment == :production

      ::Cabin::Outputs::IO.class_eval { alias :write :'<<' }
      ::Cabin::Outputs::StdlibLogger.class_eval { alias :write :'<<' }

      access_logger = Cabin::Channel.get(LogStash::Api)
      access_logger.subscribe(STDOUT)
      access_logger.level = :debug

      error_logger  = ::File.new(::File.join(::File.dirname(::File.expand_path(__FILE__)),'../../..','error.log'),"a+")
      error_logger.sync = true

      configure do
        use ::Rack::CommonLogger, access_logger
      end

      before do
        env["rack.errors"] =  error_logger
      end
    else
      set :show_exceptions, :after_handler
    end

    helpers AppHelpers

    def initialize(app=nil)
      super(app)
      @service = LogStash::Api::Service.instance
      @factory = CommandFactory.new(@service)
    end

  end
end
