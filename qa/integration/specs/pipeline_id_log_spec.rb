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

  it "should write logs with pipeline.id" do
    pipeline_name = "custom_pipeline"
    settings = {
      "path.logs" => temp_dir,
      "pipeline.id" => pipeline_name
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-w", "1" , "-e", config)
    @ls.wait_for_logstash
    sleep 2 until @ls.exited?
    plainlog_file = "#{temp_dir}/logstash-plain.log"
    expect(File.exists?(plainlog_file)).to be true
    expect(IO.read(plainlog_file) =~ /\[logstash.javapipeline\s*\]\[#{pipeline_name}\]/).to be > 0
  end
end
