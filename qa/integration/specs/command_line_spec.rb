# encoding: utf-8
require_relative "../framework/fixture"
require_relative "../framework/settings"
require_relative "../framework/helpers"

describe "CLI >" do

  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
  end

  after(:each) { @logstash.teardown }

  it "shows --help" do
    execute = @logstash.run('--help')

    expect(execute.exit_code).to eq(0)
    expect(execute.stderr_and_stdout).to include('bin/logstash [OPTIONS]')
    expect(execute.stderr_and_stdout).to include('--pipeline.id ID')
  end

end
