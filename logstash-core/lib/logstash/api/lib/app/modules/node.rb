# encoding: utf-8
require "app"

module LogStash::Api
  class Node < BaseApp

    helpers AppHelpers

    # return hot threads information
    get "/hot_threads" do
      ignore_idle_threads = params["ignore_idle_threads"] || true

      options = {
        :ignore_idle_threads => as_boolean(ignore_idle_threads),
        :human => params.has_key?("human")
      }
      options[:threads] = params["threads"].to_i if params.has_key?("threads")

      command = factory.build(:hot_threads_command)
      as    = options[:human] ? :string : :json
      respond_with(command.run(options), {:as => as})
    end

  end
end
