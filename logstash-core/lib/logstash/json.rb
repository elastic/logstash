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
      # TODO [guyboertje] remove these comments in 5.0
      # test for enumerable here to work around an omission in JrJackson::Json.dump to
      # also look for Java::JavaUtil::ArrayList, see TODO submit issue
      # o.is_a?(Enumerable) ? JrJackson::Raw.generate(o) : JrJackson::Json.dump(o)
      if o.class == String # TODO: test only, make it happen for all data structures
        duplicated_input_string = o.dup
        if duplicated_input_string.encoding != Encoding::UTF_8
          encoding_converter = Encoding::Converter.new(duplicated_input_string.encoding, Encoding::UTF_8)
          conversion_error = false
          begin
            utf_encoded_string = encoding_converter.convert(duplicated_input_string).freeze
          rescue Encoding::UndefinedConversionError => e
            # trace logging
            puts "Could not convert, #{e.inspect}"
            conversion_error = true
          ensure
            # we don't catch the error raised by `JrJackson::Base.generate`
            # and we let normalize and replace invalid unicode bytes before `JrJackson::Base.generate`
            return JrJackson::Base.generate(utf_encoded_string, options) unless conversion_error
          end
        end

        begin
          # non expensive `force_encoding` operation which changes the encoding metadata, otherwise unicode normalization rejects
          duplicated_input_string = duplicated_input_string.force_encoding(Encoding::UTF_8)
          # force UTF-8 encoding might also have invalid bytes, we try to normalize first
          # use replacement char with `scrub` if invalid bytes found
          duplicated_input_string.unicode_normalize # maybe use :nfkc?
        rescue ArgumentError => e
          # trace log
          puts "Could not normalize to unicode, #{e.inspect}"
          puts "Replacing invalid non-utf bytes with replacement char."
          duplicated_input_string.scrub!
        end
        JrJackson::Base.generate(duplicated_input_string, options)
      else
        JrJackson::Base.generate(o, options)
      end
    rescue => e
      raise LogStash::Json::GeneratorError.new(e.message)
    end

    alias_method :load, "jruby_load".to_sym
    alias_method :dump, "jruby_dump".to_sym
  end
end
