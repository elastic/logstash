require_relative "../services/service_locator"

# A class that holds all fixtures for a given test file. This deals with
# bootstrapping services, dealing with config files, inputs etc
class Fixture
  attr_reader :input
  attr_reader :config
  attr_reader :actual_output
  attr_reader :test_dir

  def initialize(test_file_location)
    @test_file_location = test_file_location
    @fixtures_dir = File.expand_path(File.join("..", "..", "fixtures"), __FILE__)
    @settings = TestSettings.new(@test_file_location)
    @service_locator = ServiceLocator.new(@settings)
    setup_services
    @config = @settings.get("config")
    @input = File.join(@fixtures_dir, @settings.get("input")) if @settings.is_set?("input")
    # this assumes current PWD.
    # TODO: Remove this when we have an erb template for LS config so you can inject such stuff
    @actual_output = @settings.get("actual_output")
  end

  def get_service(name)
    @service_locator.get_service(name)
  end

  def output_equals_expected?
    FileUtils.identical?(@actual_output, @input)
  end

  def output_exists?
    File.exists?(@actual_output)
  end

  def teardown
    File.delete(@actual_output) if @settings.is_set?(@actual_output) && output_exists?
    puts "Tearing down services"
    services = @settings.get("services")
    services.each do |name|
      @service_locator.get_service(name).teardown
    end
  end

  def setup_services
    puts "Setting up services"
    services = @settings.get("services")
    services.each do |name|
     @service_locator.get_service(name).setup
    end
    if @settings.is_set?("setup_script")
      puts "Setting up test specific fixtures"
      script = File.join(@fixtures_dir, @settings.get("setup_script"))
      `#{script}`
    end
  end

end
