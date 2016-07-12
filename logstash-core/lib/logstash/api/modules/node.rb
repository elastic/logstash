# encoding: utf-8
require "logstash/api/modules/base"

module LogStash
  module Api
    module Modules
      class Node < ::LogStash::Api::Modules::Base
        def node
          factory.build(:node)
        end
        
        get "/" do
          respond_with node.all
        end

        get "/os" do
          respond_with :os => node.os
        end

        get "/jvm" do
          respond_with :jvm => node.jvm          
        end

        get "/pipeline" do
          respond_with :pipeline => node.pipeline
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
      end
    end
  end
end
