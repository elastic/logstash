# Base class for a service like Kafka, ES, Logstash
class Service

  def initialize(name, settings)
    @name = name
    @settings = settings
    @setup_script = File.expand_path("../#{name}_setup.sh", __FILE__)
    @teardown_script = File.expand_path("../#{name}_teardown.sh", __FILE__)
  end

  def setup
    puts "Setting up #{@name} service"
    if File.exists?(@setup_script)
      `#{@setup_script}`
    else
      puts "Setup script not found for #{@name}"
    end
    puts "#{@name} service setup complete"
  end

  def teardown
    puts "Tearing down #{@name} service"
    if File.exists?(@setup_script)
      `#{@teardown_script}`
    else
      puts "Teardown script not found for #{@name}"
    end
    puts "#{@name} service teardown complete"
  end
end
