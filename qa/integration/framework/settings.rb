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

require 'yaml'

# All settings for a test, global and per test
class TestSettings
  # Setting for the entire test suite
  INTEG_TESTS_DIR = File.expand_path(File.join("..", ".."), __FILE__)
  # Test specific settings
  SUITE_SETTINGS_FILE = File.join(INTEG_TESTS_DIR, "suite.yml")
  FIXTURES_DIR = File.join(INTEG_TESTS_DIR, "fixtures")

  def initialize(test_file_path)
    test_name = File.basename(test_file_path, ".*")
    @tests_settings_file = File.join(FIXTURES_DIR, "#{test_name}.yml")
    # Global suite settings
    @suite_settings = YAML.load(ERB.new(File.new(SUITE_SETTINGS_FILE).read).result)
    # Per test settings, where one can override stuff and define test specific config
    @test_settings = YAML.load_file(@tests_settings_file)

    if verbose_mode?
      puts "Test settings file: #{@tests_settings_file}"
      puts "Suite settings file: #{SUITE_SETTINGS_FILE}"
    end

    if is_set?("config")
      if get("config").is_a?(Hash)
        tmp = {}
        get("config").each do |k, v|
          tmp[k] = get("config")[k].gsub('\n', '').split.join(" ")
        end
        @test_settings["config"] = tmp
      else
        config_string = get("config").gsub('\n', '').split.join(" ")
        @test_settings["config"] = config_string
      end
    end
  end

  def get(key)
    if @test_settings.key?(key)
      @test_settings[key]
    else
      @suite_settings[key]
    end
  end

  def verbose_mode?
    @suite_settings["verbose_mode"]
  end

  def is_set?(key)
    @suite_settings.key?(key) || @test_settings.key?(key)
  end

  def feature_flag
    @suite_settings["feature_flag"].to_s.strip
  end

  def feature_config_dir
    feature = feature_flag
    feature.empty? ? nil : File.join(FIXTURES_DIR, feature)
  end
end
