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

  # A class to normalize the invalid unicode data
  class UnicodeNormalizer

    include LogStash::Util::Loggable

    # Tries to convert input string to UTF-8 with a standard way
    # If input string is the force encoded invalid unicode:
    #   applies unicode normalization
    #   replaces invalid unicode bytes with replacement characters
    # string_data - The String data to be normalized.
    # Returns the normalized string data.
    def self.normalize_string_encoding(string_data)
      input_string = string_data.dup if string_data.frozen?
      input_string = string_data unless string_data.frozen?

      if input_string.encoding != Encoding::UTF_8
        encoding_converter = Encoding::Converter.new(input_string.encoding, Encoding::UTF_8)
        conversion_error, utf8_string = false, nil
        begin
          utf8_string = encoding_converter.convert(input_string).freeze
        rescue => e
          # we mostly get Encoding::UndefinedConversionError but let's do not expect surprise crashes
          logger.trace? && logger.trace("Could not convert, #{e.inspect}")
          conversion_error = true
        ensure
          # if we cannot convert with a standard way
          # we let normalize and replace invalid unicode bytes
          return utf8_string unless conversion_error
        end
      end

      begin
        # non expensive `force_encoding` operation which changes the encoding metadata
        # otherwise unicode normalization rejects
        input_string = input_string.force_encoding(Encoding::UTF_8)
        # force UTF-8 encoding as data might also have invalid bytes
        # we try to normalize first, use replacement char with `scrub` if invalid bytes found
        input_string.unicode_normalize! # use default :NFC normalization since decompositions may result multiple characters
      rescue => e
        logger.trace? && logger.trace("Could not normalize to unicode, #{e.inspect}")
        logger.trace? && logger.trace("Replacing invalid non-utf bytes with replacement char.")
        input_string.scrub!
      end
      input_string
    end
  end
end
