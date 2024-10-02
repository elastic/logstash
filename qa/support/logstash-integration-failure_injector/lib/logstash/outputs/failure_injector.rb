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

# encoding: utf-8

require 'logstash/inputs/base'
require 'logstash/namespace'

require_relative '../utils/failure_injector_util'

class LogStash::Outputs::FailureInjector < LogStash::Outputs::Base

  config_name "failure_injector"

  # Defines the phases where plugin needs to make a pipeline degraded state.
  # Accepts one or any of [register, receive, close]
  # Note that, order of the phases doesn't matter as it obeys on plugin phase
  # Example config to degrade the pipeline status at register and receive phase:
  # failure_injector {
  #    degrade_at => ['register', 'receive']
  # }
  config :degrade_at, :validate => :array, :default => []

  # Defines the phases where plugin needs to be crashed, causes pipeline terminated.
  # Accepts one of [register, receive, close]
  # Example config to degrade the pipeline status at register and receive phase:
  # failure_injector {
  #    crash_at => 'register'
  # }
  #
  # Note that, order of the phases doesn't matter as it obeys on plugin phase
  #   Plugin doesn't validate the order, if `crash_at` is combined with `degrade_at`, and plugin cannot simulate degraded state after crash phase
  #   Example,
  #     failure_injector {
  #       crash_at => 'register'
  #        degrade_at => ['receive']
  #     }
  config :crash_at, :validate => :string

  def initialize(params)
    FailureInjectorUtils.validate_config('output', params)
    super
  end

  def register
    @logger.debug("Registering plugin")
    degrade_or_crash_if_required('register')
  end

  def multi_receive(events)
    @logger.trace("Received #{events.size} size of events")
    degrade_or_crash_if_required('receive')
  end

  def close
    @logger.debug("Plugin is closing")
    degrade_or_crash_if_required('close')
  end

  def degrade_or_crash_if_required(phase)
    degrade(phase) if @degrade_at.include?(phase)
    crash(phase) if @crash_at && @crash_at == phase
  end

  def degrade(phase)
    @logger.debug("Degraded at #{phase} phase")
    (1..100).each { |i|
      sleep(i * 0.01)
    }
  end

  def crash(phase)
    @logger.debug("Crashing at #{phase} phase")
    raise "`logstash-output-failure_injector` is crashing at #{phase} phase"
  end

end
