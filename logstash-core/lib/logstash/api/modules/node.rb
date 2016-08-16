# encoding: utf-8
require "logstash/api/modules/base"

module LogStash
  module Api
    module Modules
      class Node < ::LogStash::Api::Modules::Base
        def node
          factory.build(:node)
        end

        get "/hot_threads" do
          ignore_idle_threads = params["ignore_idle_threads"] || true

          options = {
            :ignore_idle_threads => as_boolean(ignore_idle_threads),
            :human => params.has_key?("human")
          }
          options[:threads] = params["threads"].to_i if params.has_key?("threads")

          as = options[:human] ? :string : :json
          respond_with(node.hot_threads(options), {:as => as})
        end

        get "/?:filter?" do
          selected_fields = extract_fields(params["filter"].to_s.strip)
          respond_with node.all(selected_fields)
        end
      end
    end
  end
end
