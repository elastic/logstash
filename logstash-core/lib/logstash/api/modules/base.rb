require "logstash/api/app_helpers"
require "logstash/api/command_factory"

module LogStash
  module Api
    module Modules
      class Base < ::Sinatra::Base
        helpers AppHelpers

        # These options never change
        # Sinatra isn't good at letting you change internal settings at runtime
        # which is a requirement. We always propagate errors up and catch them
        # in a custom rack handler in the RackApp class
        set :environment, :production
        set :raise_errors, true
        set :show_exceptions, false

        attr_reader :factory

        include LogStash::Util::Loggable

        helpers AppHelpers

        def initialize(app=nil, agent)
          super(app)
          @factory = ::LogStash::Api::CommandFactory.new(LogStash::Api::Service.new(agent))
        end

        not_found do
          status 404
          as   = params.has_key?("human") ? :string : :json
          text = as == :string ? "" : {}
          respond_with(text, :as => as)
        end
      end
    end
  end
end
