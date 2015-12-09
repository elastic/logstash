# encoding: utf-8
require "logstash/json"

module LogStash::Api::AppHelpers

  def respond_with(data)
    LogStash::Json.dump(data)
  end
end
