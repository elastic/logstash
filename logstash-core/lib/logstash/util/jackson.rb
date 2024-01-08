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

module LogStash
  module Util
    module Jackson
      def self.set_jackson_defaults(logger)
        JacksonStreamReadConstraintsDefaults.new(logger).configure
      end

      class JacksonStreamReadConstraintsDefaults

        java_import com.fasterxml.jackson.core.StreamReadConstraints

        PROPERTY_MAX_STRING_LENGTH = 'logstash.jackson.stream-read-constraints.max-string-length'.freeze
        PROPERTY_MAX_NUMBER_LENGTH = 'logstash.jackson.stream-read-constraints.max-number-length'.freeze
        PROPERTY_MAX_NESTING_DEPTH = 'logstash.jackson.stream-read-constraints.max-nesting-depth'.freeze

        def initialize(logger)
          @logger = logger
        end

        public

        def configure
          max_string_len = get_default_value_override!(PROPERTY_MAX_STRING_LENGTH)
          max_num_len = get_default_value_override!(PROPERTY_MAX_NUMBER_LENGTH)
          max_nesting_depth = get_default_value_override!(PROPERTY_MAX_NESTING_DEPTH)

          if max_string_len || max_num_len || max_nesting_depth
            begin
              override_default_stream_read_constraints(max_string_len, max_num_len, max_nesting_depth)
            rescue java.lang.IllegalArgumentException => e
              raise LogStash::ConfigurationError, "Invalid `logstash.jackson.*` system properties configuration: #{e.message}"
            end
          end
        end

        private

        def get_default_value_override!(property)
          value = get_property_value(property)
          return if value.nil?

          begin
            int_value = java.lang.Integer.parseInt(value)

            if int_value < 1
              raise LogStash::ConfigurationError, "System property '#{property}' must be bigger than zero. Received: #{int_value}"
            end

            @logger.info("Jackson default value override `#{property}` configured to `#{int_value}`")

            int_value
          rescue java.lang.NumberFormatException => _e
            raise LogStash::ConfigurationError, "System property '#{property}' must be a positive integer value. Received: #{value}"
          end
        end

        def get_property_value(name)
          java.lang.System.getProperty(name)
        end

        def override_default_stream_read_constraints(max_string_len, max_num_len, max_nesting_depth)
          builder = new_stream_read_constraints_builder
          builder.maxStringLength(max_string_len) if max_string_len
          builder.maxNumberLength(max_num_len) if max_num_len
          builder.maxNestingDepth(max_nesting_depth) if max_nesting_depth

          StreamReadConstraints.overrideDefaultStreamReadConstraints(builder.build)
        end

        def new_stream_read_constraints_builder
          StreamReadConstraints::builder
        end
      end
    end
  end
end