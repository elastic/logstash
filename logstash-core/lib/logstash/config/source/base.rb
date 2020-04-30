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

module LogStash module Config module Source
  class Base
    attr_reader :conflict_messages

    def initialize(settings)
      @settings = settings
      @conflict_messages = []
    end

    def pipeline_configs
      raise NotImplementedError, "`#pipeline_configs` must be implemented!"
    end

    def match?
      raise NotImplementedError, "`match?` must be implemented!"
    end

    def config_conflict?
      raise NotImplementedError, "`config_conflict?` must be implemented!"
    end

    def config_reload_automatic_setting
      @settings.get_setting("config.reload.automatic")
    end

    def config_reload_automatic
      config_reload_automatic_setting.value
    end

    def config_reload_automatic?
      config_reload_automatic_setting.set?
    end

    def config_string_setting
      @settings.get_setting("config.string")
    end

    def config_string
      config_string_setting.value
    end

    def config_string?
      !config_string.nil?
    end

    def config_path_setting
      @settings.get_setting("path.config")
    end

    def config_path
      config_path_setting.value
    end

    def config_path?
      !(config_path.nil? || config_path.empty?)
    end

    def modules_cli_setting
      @settings.get_setting("modules.cli")
    end

    def modules_cli
      modules_cli_setting.value
    end

    def modules_cli?
      !(modules_cli.nil? || modules_cli.empty?)
    end

    def modules_setting
      @settings.get_setting("modules")
    end

    def modules
      modules_setting.value
    end

    def modules?
      !(modules.nil? || modules.empty?)
    end

    def both_module_configs?
      modules_cli? && modules?
    end

    def modules_defined?
      modules_cli? || modules?
    end
  end
end end end
