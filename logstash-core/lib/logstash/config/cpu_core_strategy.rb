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

require "logstash/config/defaults"

module LogStash module Config module CpuCoreStrategy
  extend self

  def maximum
    LogStash::Config::Defaults.cpu_cores
  end

  def fifty_percent
    [1, (maximum * 0.5)].max.floor
  end

  def seventy_five_percent
    [1, (maximum * 0.75)].max.floor
  end

  def twenty_five_percent
    [1, (maximum * 0.25)].max.floor
  end

  def max_minus_one
    [1, (maximum - 1)].max.floor
  end

  def max_minus_two
    [1, (maximum - 2)].max.floor
  end
end end end
