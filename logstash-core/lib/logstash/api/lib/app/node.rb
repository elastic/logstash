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
        :ignore_idle_threads => as_boolean(ignore_idle_threads)
      }
      command = factory.build(:hot_threads_command)
      respond_with(command.run(options), :string)
    end

  end
end
