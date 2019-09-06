require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"

describe "Test Logstash Pipeline id" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    # used in multiple LS tests
    @ls = @fixture.get_service("logstash")
  }

  after(:all) {
    @fixture.teardown
  }

  before(:each) {
    # backup the application settings file -- logstash.yml
    FileUtils.cp(@ls.application_settings_file, "#{@ls.application_settings_file}.original")
  }

  after(:each) {
    @ls.teardown
    # restore the application settings file -- logstash.yml
    FileUtils.mv("#{@ls.application_settings_file}.original", @ls.application_settings_file)
  }

  let(:temp_dir) { Stud::Temporary.directory("logstash-pipelinelog-test") }
  let(:config) { @fixture.config("root") }
  let(:initial_config_file) { config_to_temp_file(@fixture.config("root")) }

  it "should write logs with pipeline.id" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1" , "-e", config)
    wait_logstash_process_terminate()
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exists?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /\[logstash.javapipeline\s*\]\[#{pipeline_name}\]/).to be > 0
  end

  it "write pipeline config in logs - source:config string" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1" , "-e", config)
    wait_logstash_process_terminate()
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exists?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /Starting pipeline.*"pipeline.sources"=>\["config string"\]/).to be > 0
  end

  it "write pipeline config in logs - source:config file" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1", "-f", "#{initial_config_file}")
    wait_logstash_process_terminate()
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exists?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /Starting pipeline.*"pipeline.sources"=>\["#{initial_config_file}"\]/).to be > 0
  end

  @private
  def wait_logstash_process_terminate
    num_retries = 100
    try(num_retries) do
      expect(@ls.exited?).to be(true)
    end
    expect(@ls.exit_code).to be(0)
  end
end
