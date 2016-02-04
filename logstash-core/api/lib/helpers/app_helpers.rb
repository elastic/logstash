# encoding: utf-8
require "logstash/json"

module LogStash::Api::AppHelpers

  def respond_with(data, as=:json)
    if as == :json
      content_type "application/json"
      LogStash::Json.dump(data)
    else
      content_type "text/plain"
      data.to_s
    end
  end

  def as_boolean(string)
    return true   if string == true   || string =~ (/(true|t|yes|y|1)$/i)
    return false  if string == false  || string.blank? || string =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end
end
