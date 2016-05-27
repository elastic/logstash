require "logstash/api/app_helpers"
require "logstash/api/command_factory"

module LogStash
  module Api
    module Modules
      class Base < ::Sinatra::Base
        helpers AppHelpers

        attr_reader :factory

        if settings.environment != :production
          set :raise_errors, true
          set :show_exceptions, :after_handler
        end

        include LogStash::Util::Loggable

        helpers AppHelpers

        def initialize(app=nil)
          super(app)
          @factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.instance)
        end

        not_found do
          status 404
          as   = params.has_key?("human") ? :string : :json
          text = as == :string ? "" : {}
          respond_with(text, :as => as)
        end

        error do
          e = env['sinatra.error']
          logger.error(e.message, :url => request.url, :ip => request.ip, :params => request.params, :class => e.class.name, :backtrace => e.backtrace)
        end

      end
    end
  end
end
