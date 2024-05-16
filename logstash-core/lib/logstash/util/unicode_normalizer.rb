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

    # Tries to normalize input string to UTF-8 when
    #   input string encoding is not UTF-8,
    #   and replaces invalid unicode bytes with replacement characters ('uFFFD')
    # string_data - The String data to be normalized.
    # Returns the normalized string data.
    def self.normalize_string_encoding(string_data)
      # when given BINARY-flagged string, assume it is UTF-8 so that
      # subsequent cleanup retains valid UTF-8 sequences
      source_encoding = string_data.encoding
      source_encoding = Encoding::UTF_8 if source_encoding == Encoding::BINARY
      string_data.encode(Encoding::UTF_8, source_encoding, invalid: :replace, undef: :replace).scrub
    end
  end
end
