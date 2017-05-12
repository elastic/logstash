# Base class for a service like Kafka, ES, Logstash
class Service

  attr_reader :settings

  def initialize(name, settings)
    @name = name
    @settings = settings
    @working_dir = File.dirname(__FILE__)
    @install_dir = File.join(@working_dir, 'installed')
    @home = File.join(@install_dir, name)
    @setup_script = File.expand_path("../#{name}_setup.sh", __FILE__)
    @teardown_script = File.expand_path("../#{name}_teardown.sh", __FILE__)
  end

  def setup
    # Create the services' home directory.
    Dir.mkdir @install_dir unless Dir.exist? @install_dir
    puts "Setting up #{@name} service"
    if defined? do_setup
      do_setup
    else
      if File.exists?(@setup_script)
        `#{@setup_script}`
      else
        puts "Setup script not found for #{@name}"
      end
    end
    puts "#{@name} service setup complete"
  end

  def teardown
    puts "Tearing down #{@name} service"
    if defined? do_stop
      do_stop
    else
      if File.exists?(@setup_script)
        `#{@teardown_script}`
      else
        puts "Teardown script not found for #{@name}"
      end
    end
    puts "#{@name} service teardown complete"
  end

  def start
    puts "Starting #{@name} service."
    if defined? do_start
      do_start
    else
      puts "Start routine is not implemented."
    end
    puts "Start complete."
  end

  def stop
    puts "Stopping #{@name} service."
    if defined? do_stop
      do_stop
    else
      puts "Stop routine is not implemented."
    end
    puts "Stop complete."
  end

end
