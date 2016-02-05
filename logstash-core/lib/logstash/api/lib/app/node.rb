# encoding: utf-8
require "app"
require "app/stats/hotthreads_command"

module LogStash::Api
  class Node < BaseApp

    helpers AppHelpers

    # return hot threads information
    get "/hot_threads" do
      top_threads_count = params["threads"] || 3
      ignore_idle_threads = params["ignore_idle_threads"] || true
      options = {
        :threads => top_threads_count.to_i,
        :ignore_idle_threads => as_boolean(ignore_idle_threads),
        :human => params.has_key?("human")
      }
      command = factory.build(:hot_threads_command)
      type    = options[:human] ? :string : :json
      respond_with(command.run(options), type)
    end

  end
end
