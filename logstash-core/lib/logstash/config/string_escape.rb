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

require 'concurrent/set'

require_relative '../util/loggable'

module LogStash; module Config; class StringEscape

  include Util::Loggable

  def initialize(string_escape_helper)
    @string_escape_helper = string_escape_helper
  end

  DISABLED = new(org.logstash.common.StringEscapeHelper::DISABLED)
  MINIMAL  = new(org.logstash.common.StringEscapeHelper::MINIMAL)

  def process_escapes(input)
    @string_escape_helper.unescape(input)
  end

  class << self

    def process_escapes(input)
      log_deprecation(caller.first)
      MINIMAL.process_escapes(input)
    end

    private

    DEPRECATION_CALLSITES = Concurrent::Set.new
    private_constant :DEPRECATION_CALLSITES

    def log_deprecation(callsite)
      return unless DEPRECATION_CALLSITES.size < 128 && DEPRECATION_CALLSITES.add?(callsite)

      deprecation_logger.deprecated("#{StringEscape}#process_escapes is deprecated and will be removed in a future major release of Logstash (at `#{callsite}`)")
    end
  end
end end end
