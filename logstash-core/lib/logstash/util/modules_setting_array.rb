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

require "forwardable"
require "logstash/util/password"

module LogStash module Util class ModulesSettingArray
  extend Forwardable
  DELEGATED_METHODS = [].public_methods.reject{|symbol| symbol.to_s.end_with?('__')}

  def_delegators :@original, *DELEGATED_METHODS

  attr_reader :original
  def initialize(value)
    unless value.is_a?(Array)
      raise ArgumentError.new("Module Settings must be an Array. Received: #{value.class}")
    end
    @original = value
    # wrap passwords
    @original.each do |hash|
      hash.keys.select{|key| key.to_s.end_with?('password') && !hash[key].is_a?(LogStash::Util::Password)}.each do |key|
        hash[key] = LogStash::Util::Password.new(hash[key])
      end
    end
  end

  def __class__
    LogStash::Util::ModulesSettingArray
  end
end end end
