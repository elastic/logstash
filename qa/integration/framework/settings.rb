require 'yaml'

# All settings for a test, global and per test
class TestSettings

  def initialize(test_file_path)
    # Setting for the entire test suite
    integ_tests_dir = File.expand_path(File.join("..", ".."), __FILE__)
    @suite_settings_file = File.join(integ_tests_dir, "suite.yml")
    # Test specific settings
    fixtures_dir = File.join(integ_tests_dir, "fixtures")
    test_name = File.basename(test_file_path, ".*" )
    @tests_settings_file = File.join(fixtures_dir, "#{test_name}.yml")
    # Global suite settings
    @suite_settings = YAML.load_file(@suite_settings_file)
    # Per test settings, where one can override stuff and define test specific config
    @test_settings = YAML.load_file(@tests_settings_file)
    if is_set?("config")
      config_string = get("config").gsub('\n','').split.join(" ")
      @test_settings["config"] = config_string
    end
  end

  def get(key)
    if @test_settings.key?(key)
      @test_settings[key]
    else
      @suite_settings[key]
    end
  end

  def is_set?(key)
    @suite_settings.key?(key) || @test_settings.key?(key)
  end
end
