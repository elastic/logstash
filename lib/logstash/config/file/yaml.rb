require "logstash/config/file"
require "yaml"

class LogStash::Config::File::Yaml < LogStash::Config::File
  def _get_config(data)
      return YAML.load(data)
  end
end
