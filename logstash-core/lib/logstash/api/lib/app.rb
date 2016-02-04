# encoding: utf-8
require "cabin"
require "logstash/json"
require "app_helpers"
require "app/service"
require "app/command_factory"

module LogStash::Api
  class BaseApp < ::Sinatra::Application

    attr_reader :factory

    if settings.environment != :production
      set :show_exceptions, :after_handler
    end

    helpers AppHelpers

    def initialize(app=nil)
      super(app)
      @factory = CommandFactory.new(settings.service)
    end

  end
end
