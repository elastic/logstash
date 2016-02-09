# encoding: utf-8
require "cabin"
require "logstash/json"
require "helpers/app_helpers"
require "app/service"
require "app/command_factory"
require "logstash/util/loggable"

module LogStash::Api
  class BaseApp < ::Sinatra::Application

    attr_reader :factory

    if settings.environment != :production
      set :raise_errors, true
      set :show_exceptions, :after_handler
    end

    include LogStash::Util::Loggable

    helpers AppHelpers

    def initialize(app=nil)
      super(app)
      @factory = CommandFactory.new(settings.service)
    end

    error do
      logger.error(env['sinatra.error'].message, :url => request.url, :ip => request.ip, :params => request.params)
    end

  end
end
