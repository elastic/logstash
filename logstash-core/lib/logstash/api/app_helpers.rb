# encoding: utf-8
require "logstash/json"

module LogStash::Api::AppHelpers

  def respond_with(data, options={})
    as     = options.fetch(:as, :json)
    pretty = params.has_key?("pretty")

    if as == :json
      unless options.include?(:exclude_default_metadata)
        data = default_metadata.merge(data)
      end
      content_type "application/json"
      LogStash::Json.dump(data, {:pretty => pretty})
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

  def default_metadata
    @factory.build(:default_metadata).all
  end
end
