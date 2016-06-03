# encoding: utf-8
require "logstash/api/modules/base"

module LogStash
  module Api
    module Modules
      class Node < ::LogStash::Api::Modules::Base
        # return hot threads information
        get "/hot_threads" do
          ignore_idle_threads = params["ignore_idle_threads"] || true

          options = {
            :ignore_idle_threads => as_boolean(ignore_idle_threads),
            :human => params.has_key?("human")
          }
          options[:threads] = params["threads"].to_i if params.has_key?("threads")

          stats = factory.build(:stats)
          as    = options[:human] ? :string : :json
          respond_with(stats.hot_threads(options), {:as => as})
        end
      end
    end
  end
end
