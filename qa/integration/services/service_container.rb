require_relative "service"
require "docker"

# Represents a service running within a container.
class ServiceContainer < Service

  def initialize(name, settings)
    super(name, settings)

    @base_image_context = File.expand_path("../dockerized", __FILE__)

    @image_context = File.join(@base_image_context, @name)

    # Options to create the container.
    @container_create_opts = {}
  end

  def setup
    puts "Setting up #{@name} service."

    puts "Building the base container image."
    @base_image = Docker::Image.build_from_dir(@base_image_context)
    # Tag the base image.
    #Caution: change this tag can cause failure to build the service container.
    @base_image.tag('repo' => 'logstash', 'tag' => 'ci_sandbox', force: true)
    puts "Finished building the base image."

    puts "Building the container image."
    self.build_image
    puts "Finished building the image."

    puts "Starting the container."
    self.start_container
    puts "Finished starting the container."

    puts "Finished setting up #{@name} service."
  end

  def teardown
    puts "Tearing down #{@name} service."

    puts "Stop the container."
    self.stop_container
    puts "Finished stopping the container."

    puts "Finished tearing down of #{@name} service."
  end

  def build_image
    @image = Docker::Image.build_from_dir(@image_context)
  end

  def start_container
    @container_create_opts[:Image] = @image.id
    @container = Docker::Container.create(@container_create_opts)
    @container.start
  end

  def stop_container
    @container.stop
    @container.delete(:force => true, :volumes => true)
  end

  # Get environment variable from container's ENV.
  def envvar(var)
    # Exec command returns an array with [[stdout], [stderr], exit_code] layout.
    res = @container.exec(['printenv', var])
    res[0].join(" ").chomp
  end

  # Get path to certificates directory.
  def certificates_dir
    envvar("CERTIFICATES_DIR")
  end

  # Copy certificates from container to directory in the host.
  def certificates(dest_dir)
    FileUtils.mkdir_p(dest_dir)
    cert_dir = certificates_dir
    ["certificate.key", "certificate.crt"].each do |file|
      File.open(File.join(dest_dir, file), "w") do |io|
        # Use container's file separator (i.e. Linux)
        io.write(@container.read_file(cert_dir.chomp + "/" + file))
      end
    end
  end

end
