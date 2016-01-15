# encoding: utf-8
require "logstash/json"

module LogStash::Api::AppHelpers

  def respond_with(data, as=:json)
    if as == :json
      LogStash::Json.dump(data)
    else
      data.to_s
    end
  end
end
