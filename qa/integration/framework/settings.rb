require 'yaml'

# All settings for a test, global and per test
class TestSettings
  # Setting for the entire test suite
  INTEG_TESTS_DIR = File.expand_path(File.join("..", ".."), __FILE__)
  # Test specific settings
  SUITE_SETTINGS_FILE = File.join(INTEG_TESTS_DIR, "suite.yml")
  FIXTURES_DIR = File.join(INTEG_TESTS_DIR, "fixtures")

  def initialize(test_file_path)
    test_name = File.basename(test_file_path, ".*" )
    @tests_settings_file = File.join(FIXTURES_DIR, "#{test_name}.yml")
    # Global suite settings
    @suite_settings = YAML.load_file(SUITE_SETTINGS_FILE)
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
          tmp[k] = get("config")[k].gsub('\n','').split.join(" ")
        end
        @test_settings["config"] = tmp
      else
        config_string = get("config").gsub('\n','').split.join(" ")
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
end
