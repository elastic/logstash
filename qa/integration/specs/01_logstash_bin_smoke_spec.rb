require_relative '../framework/fixture'

require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"
require 'json'
require 'open-uri'

describe "Test Logstash instance" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # used in multiple LS tests
    @ls1 = @fixture.get_service("logstash")
    @ls2 = LogstashService.new(@fixture.settings)
  }

  after(:all) {
    @fixture.teardown
  }

  after(:each) {
    @ls1.teardown
    @ls2.teardown
  }

  let(:file_config1) { Stud::Temporary.file.path }
  let(:file_config2) { Stud::Temporary.file.path }
  let(:file_config3) { Stud::Temporary.file.path }

  let(:num_retries) { 10 }
  let(:config1) { config_to_temp_file(@fixture.config("root", { :port => port1, :random_file => file_config1 })) }
  let(:config2) { config_to_temp_file(@fixture.config("root", { :port => port2 , :random_file => file_config2 })) }
  let(:config3) { config_to_temp_file(@fixture.config("root", { :port => port3, :random_file => file_config3 })) }
  let(:port1) { random_port }
  let(:port2) { random_port }
  let(:port3) { random_port }

  let(:persistent_queue_settings) { { "queue.type" => "persisted" } }

  it "can start the embedded http server on default port 9600" do
    @ls1.start_with_stdin
    try(num_retries) do
      expect(is_port_open?(9600)).to be true
    end
  end

  context "multiple instances" do
    it "cannot be started on the same box with the same path.data" do
      tmp_path = Stud::Temporary.pathname
      tmp_data_path = File.join(tmp_path, "data")
      FileUtils.mkdir_p(tmp_data_path)
      @ls1.spawn_logstash("-f", config1, "--path.data", tmp_data_path)
      sleep(0.1) until File.exist?(file_config1) && File.size(file_config1) > 0 # Everything is started successfully at this point
      expect(is_port_open?(9600)).to be true

      @ls2.spawn_logstash("-f", config2, "--path.data", tmp_data_path)
      try(20) do
        expect(@ls2.exited?).to be(true)
      end
      expect(@ls2.exit_code).to be(1)
    end

    it "can be started on the same box with different path.data" do
      tmp_path_1 = Stud::Temporary.pathname
      tmp_data_path_1 = File.join(tmp_path_1, "data")
      FileUtils.mkdir_p(tmp_data_path_1)
      tmp_path_2 = Stud::Temporary.pathname
      tmp_data_path_2 = File.join(tmp_path_2, "data")
      FileUtils.mkdir_p(tmp_data_path_2)
      @ls1.spawn_logstash("-f", config1, "--path.data", tmp_data_path_1)
      sleep(0.1) until File.exist?(file_config1) && File.size(file_config1) > 0 # Everything is started successfully at this point
      expect(is_port_open?(9600)).to be true

      @ls2.spawn_logstash("-f", config2, "--path.data", tmp_data_path_2)
      sleep(0.1) until File.exist?(file_config2) && File.size(file_config2) > 0 # Everything is started successfully at this point
      expect(@ls2.exited?).to be(false)
    end

    it "can be started on the same box with automatically trying different ports for HTTP server" do
      if @ls2.settings.feature_flag != "persistent_queues"
        @ls1.spawn_logstash("-f", config1)
        sleep(0.1) until File.exist?(file_config1) && File.size(file_config1) > 0 # Everything is started successfully at this point
        expect(is_port_open?(9600)).to be true

        puts "will try to start the second LS instance on 9601"

        # bring up new LS instance
        tmp_path = Stud::Temporary.pathname
        tmp_data_path = File.join(tmp_path, "data")
        FileUtils.mkdir_p(tmp_data_path)
        @ls2.spawn_logstash("-f", config2, "--path.data", tmp_data_path)
        sleep(0.1) until File.exist?(file_config2) && File.size(file_config2) > 0 # Everything is started successfully at this point
        expect(is_port_open?(9601)).to be true
        expect(@ls1.process_id).not_to eq(@ls2.process_id)
      else
        # Make sure that each instance use a different `path.data`
        path = Stud::Temporary.pathname
        FileUtils.mkdir_p(File.join(path, "data"))
        data = File.join(path, "data")
        settings = persistent_queue_settings.merge({ "path.data" => data })
        IO.write(File.join(path, "logstash.yml"), YAML.dump(settings))

        @ls1.spawn_logstash("--path.settings", path, "-f", config1)
        sleep(0.1) until File.exist?(file_config1) && File.size(file_config1) > 0 # Everything is started successfully at this point
        expect(is_port_open?(9600)).to be true

        puts "will try to start the second LS instance on 9601"

        # bring up new LS instance
        path = Stud::Temporary.pathname
        FileUtils.mkdir_p(File.join(path, "data"))
        data = File.join(path, "data")
        settings = persistent_queue_settings.merge({ "path.data" => data })
        IO.write(File.join(path, "logstash.yml"), YAML.dump(settings))
        @ls2.spawn_logstash("--path.settings", path, "-f", config2)
        sleep(0.1) until File.exist?(file_config2) && File.size(file_config2) > 0 # Everything is started successfully at this point
        expect(is_port_open?(9601)).to be true

        expect(@ls1.process_id).not_to eq(@ls2.process_id)
      end
    end
  end

  it "gets the right version when asked" do
    expected = YAML.load_file(LogstashService::LS_VERSION_FILE)
    expect(@ls1.get_version.strip).to eq("logstash #{expected['logstash']}")
  end

  it "should still merge when -e is specified and -f has no valid config files" do
    config_string = "input { tcp { port => #{port1} } }"
    @ls1.spawn_logstash("-e", config_string, "-f" "/tmp/foobartest")
    @ls1.wait_for_logstash

    try(20) do
      expect(is_port_open?(port1)).to be true
    end
  end

  it "should not start when -e is not specified and -f has no valid config files" do
    @ls2.spawn_logstash("-e", "", "-f" "/tmp/foobartest")
    try(num_retries) do
      expect(is_port_open?(9600)).to be_falsey
    end
  end

  it "should merge config_string when both -f and -e is specified" do
    config_string = "input { tcp { port => #{port1} } }"
    @ls1.spawn_logstash("-e", config_string, "-f", config3)
    @ls1.wait_for_logstash

    # Both ports should be reachable
    try(20) do
      expect(is_port_open?(port1)).to be true
    end

    try(20) do
      expect(is_port_open?(port3)).to be true
    end
  end

  def get_id
    JSON.parse(open("http://localhost:9600/").read)["id"]
  end

  it "should keep the same id between restarts" do
    config_string = "input { tcp { port => #{port1} } }"

    start_ls = lambda {
      @ls1.spawn_logstash("-e", config_string, "-f", config3)
      @ls1.wait_for_logstash
    }
    start_ls.call()
    first_id = get_id
    @ls1.teardown
    start_ls.call()
    second_id = get_id
    expect(first_id).to eq(second_id)
  end
end
