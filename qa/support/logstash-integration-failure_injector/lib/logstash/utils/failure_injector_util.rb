# encoding: utf-8

class FailureInjectorUtils

  def self.validate_config(type, params)
    type_error_message = "`logstash-integration-failure_injector` accepts 'filter' or 'output' type."
    raise type_error_message unless type
    raise type_error_message unless %w(filter output).include?(type)

    plugin_phase = type == 'output' ? 'receive' : 'filter'
    accepted_configs = ['register', "#{plugin_phase}", 'close']
    config_error_message = "failure_injector #{type} plugin accepts #{accepted_configs} configs but received"
    params['degrade_at']&.each do | degrade_phase |
      raise "#{config_error_message} #{degrade_phase}" unless accepted_configs.include?(degrade_phase)
    end

    crash_at = params['crash_at']
    puts "crash_at: #{crash_at}"
    raise "#{config_error_message} #{crash_at}" if crash_at && !accepted_configs.include?(crash_at)
  end
end