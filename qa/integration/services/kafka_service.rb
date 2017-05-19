require_relative "service"
require "docker"

class KafkaService < Service
  def initialize(settings)
    super("kafka", settings)
  end

  def setup
    @kafka_image = Docker::Image.build_from_dir(File.expand_path("../kafka_dockerized", __FILE__))
                     .insert_local(
                       'localPath' => File.join(TestSettings::FIXTURES_DIR, "how_sample.input"),
                       'outputPath' => '/')
    @kafka_container = Docker::Container.create(:Image => @kafka_image.id,
                                                :HostConfig => {
                                                  :PortBindings => {
                                                    '9092/tcp' => [{ :HostPort => '9092' }],
                                                    '2181/tcp' => [{ :HostPort => '2181' }]
                                                  }
                                                }, :Cmd => ["/bin/bash", "-l", "/run.sh"])
    @kafka_container.start
    super()
  end

  def teardown
    @kafka_container.kill(:signal => "SIGHUP")
    @kafka_container.delete(:force => true, :volumes => true)
    super()
  end
end
