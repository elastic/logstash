require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "yaml"

describe "Test Logstash Slowlog" do
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

  let(:temp_dir) { Stud::Temporary.directory("logstash-slowlog-test") }
  let(:config) { @fixture.config("root") }

  it "should write logs to a new dir" do
    settings = {
      "path.logs" => temp_dir,
      "slowlog.threshold.warn" => "500ms"
    }
    IO.write(@ls.application_settings_file, settings.to_yaml)
    @ls.spawn_logstash("-e", config)
    @ls.wait_for_logstash
    sleep 1 until @ls.exited?
    slowlog_file = "#{temp_dir}/logstash-slowlog-plain.log"
    expect(File.exists?(slowlog_file)).to be true
    expect(IO.read(slowlog_file).split("\n").size).to eq(2)
  end
end
