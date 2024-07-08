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

require "logstash/environment"
require "logstash/util/unicode_normalizer"
require "jrjackson"

module LogStash
  module Json
    extend self

    def jruby_load(data, options = {})
      # TODO [guyboertje] remove these comments in 5.0
      # options[:symbolize_keys] ? JrJackson::Raw.parse_sym(data) : JrJackson::Raw.parse_raw(data)

      JrJackson::Ruby.parse(data, options)
    rescue JrJackson::ParseError => e
      raise LogStash::Json::ParserError.new(e.message)
    end

    def jruby_dump(o, options = {})
      encoding_normalized_data = normalize_encoding(o)

      # TODO [guyboertje] remove these comments in 5.0
      # test for enumerable here to work around an omission in JrJackson::Json.dump to
      # also look for Java::JavaUtil::ArrayList, see TODO submit issue
      # o.is_a?(Enumerable) ? JrJackson::Raw.generate(o) : JrJackson::Json.dump(o)
      JrJackson::Base.generate(encoding_normalized_data, options)
    rescue => e
      raise LogStash::Json::GeneratorError.new(e.message)
    end

    alias_method :load, "jruby_load".to_sym
    alias_method :dump, "jruby_dump".to_sym

    private
    def normalize_encoding(data)
      case data
      when String
        LogStash::UnicodeNormalizer.normalize_string_encoding(data)
      when Array
        data.map { |item| normalize_encoding(item) }
      when Hash
        # origin key might change when normalizing, so requires transformation
        data.to_hash # if coming from jruby objects such as UnmodifiableMap
            .transform_keys { |key| normalize_encoding(key) }
            .transform_values { |value| normalize_encoding(value) }
      else
        data # use as it is
      end
    end
  end
end
