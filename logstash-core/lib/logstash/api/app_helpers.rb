# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/json"
require "logstash/api/errors"
require "logstash/util"

module LogStash::Api::AppHelpers
  # This method handle both of the normal flow *happy path*
  # and the display or errors, if more custom logic is added here
  # it will make sense to separate them.
  #
  # See `#error` method in the `LogStash::Api::Module::Base`
  def respond_with(data, options = {})
    as     = options.fetch(:as, :json)
    filter = options.fetch(:filter, "")

    status data.respond_to?(:status_code) ? data.status_code : 200

    if as == :json
      if api_error?(data)
        data = generate_error_hash(data)
      else
        selected_fields = extract_fields(filter.to_s.strip)
        data.select! { |k, v| selected_fields.include?(k) } unless selected_fields.empty?
        unless options.include?(:exclude_default_metadata)
          data = data.to_hash
          if data.values.size == 0 && selected_fields.size > 0
            raise LogStash::Api::NotFoundError
          end
          data = default_metadata.merge(data)
        end
      end

      content_type "application/json"
      LogStash::Json.dump(data, {:pretty => pretty?})
    else
      content_type "text/plain"
      data.to_s
    end
  end

  protected
  def extract_fields(filter_string)
    (filter_string.empty? ? [] : filter_string.split(",").map { |s| s.strip.to_sym })
  end

  def as_boolean(string)
    return true if string == true
    return false if string == false

    return true if string =~ (/(true|t|yes|y|1)$/i)
    return false if  LogStash::Util.blank?(string) || string =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{string}\"")
  end

  protected
  def default_metadata
    @factory.build(:default_metadata).all
  end

  def api_error?(error)
    error.is_a?(LogStash::Api::ApiError)
  end

  def pretty?
    params.has_key?("pretty")
  end

  def generate_error_hash(error)
    {
      :path => request.path,
      :status => error.status_code,
      :error => error.to_hash
    }
  end

  def human?
    params.has_key?("human") && (params["human"].nil? || as_boolean(params["human"]) == true)
  end
end
