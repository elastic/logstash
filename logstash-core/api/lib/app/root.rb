# encoding: utf-8
require "app"

module LogStash::Api
  class Root < BaseApp

    get "/" do
      content = { "name" => "Logstash API",
                  "version" => { "number" => LOGSTASH_CORE_VERSION },
                }
      respond_with content
    end

  end
end
