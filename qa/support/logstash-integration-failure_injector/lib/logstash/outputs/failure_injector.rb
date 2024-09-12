# encoding: utf-8

require 'logstash/inputs/base'
require 'logstash/namespace'

require_relative '../utils/failure_injector_util'

class LogStash::Outputs::FailureInjector < LogStash::Outputs::Base

  config_name "failure_injector"

  # one or any of [register, receive, close]
  config :degrade_at, :validate => :array, :default => []

  # one of [register, receive, close]
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
    degrate(phase) if @degrade_at.include?(phase)
    crash(phase) if @crash_at && @crash_at == phase
  end

  def degrate(phase)
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
