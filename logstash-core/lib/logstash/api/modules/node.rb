# encoding: utf-8
require "logstash/api/modules/base"
require "logstash/api/errors"

module LogStash
  module Api
    module Modules
      class Node < ::LogStash::Api::Modules::Base
        def node
          factory.build(:node)
        end

        get "/hot_threads" do
          ignore_idle_threads = params["ignore_idle_threads"] || true

          options = { :ignore_idle_threads => as_boolean(ignore_idle_threads) }
          options[:threads] = params["threads"].to_i if params.has_key?("threads")

          as = human? ? :string : :json
          respond_with(node.hot_threads(options), {:as => as})
        end

         get "/?:filter?" do
           selected_fields = extract_fields(params["filter"].to_s.strip)
           values = node.all(selected_fields)

           if values.size == 0
             raise NotFoundError
           else
             respond_with(values)
           end
         end
      end
    end
  end
end
