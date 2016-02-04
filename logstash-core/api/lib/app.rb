# encoding: utf-8
require "cabin"
require "logstash/json"
require "helpers/app_helpers"
require "app/service"
require "app/command_factory"
require "logstash/util/loggable"
require "helpers/cabin_compatibility_layer"

module LogStash::Api
  class BaseApp < ::Sinatra::Application

    attr_reader :factory

    ::Cabin::Channel.class_eval do
      include ::Cabin::Mixins::SinatraLogger
    end

    if settings.environment != :production
      set :raise_errors, true
      set :show_exceptions, :after_handler
    end

    include LogStash::Util::Loggable

    configure do
      use Rack::CommonLogger, logger
    end

    helpers AppHelpers

    def initialize(app=nil)
      super(app)
      @factory = CommandFactory.new(settings.service)
    end

    error do
      logger.error(env['sinatra.error'].message)
    end

  end
end
