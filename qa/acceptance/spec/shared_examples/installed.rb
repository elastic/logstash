require_relative '../spec_helper'
require          'logstash/version'

RSpec.shared_examples "installable" do |host, options|

  before(:each) do
    current_example.metadata[:platform] = options["type"]
    install(package_for(options["type"], LOGSTASH_VERSION), host)
  end

  it "is installed on #{options["host"]}" do
    expect("logstash").to be_installed.on(host)
  end

  it "is running on #{options["host"]}" do
    start_service("logstash", host)
    expect("logstash").to be_running.on(host)
    stop_service("logstash", host)
  end

  it "is removable on #{options["host"]}" do
    uninstall("logstash", host)
    expect("logstash").to be_removed.on(host)
  end
end
