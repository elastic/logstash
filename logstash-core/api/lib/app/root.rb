# encoding: utf-8
require "app"

module LogStash::Api
  class Root < BaseApp

    get "/" do
      content = { "name" => "Logstash API",
                  "version" => { "number" => "0.1.0" },
                }
      respond_with content
    end

  end
end
