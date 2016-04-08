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

    get "/_directory" do
      data = {}
      ROUTES.each_pair do |namespace, _routes|
        routes = {}
        _routes.each_pair do |verb, methods|
          next if "HEAD" == verb
          routes[verb] = methods.map { |m| "http://localhost:9600#{namespace}/#{m[0].source.gsub("\\A/","").gsub("\\z", "")}" }
        end
        data[namespace] = routes
      end
      respond_with data
    end

    not_found do
      status 404
      as   = params.has_key?("human") ? :string : :json
      text = as == :string ? "" : {}
      respond_with(text, :as => as)
    end

    error do
      logger.error(env['sinatra.error'].message, :url => request.url, :ip => request.ip, :params => request.params)
    end

  end
end
