# Encoding: utf-8
require_relative "../spec_helper"
require_relative "../../../lib/logstash/version"

describe "bin/logstash" do
  it "returns the logstash version" do
    result = command("bin/logstash --version")
    expect(result.exit_status).to eq(0)
    expect(result.stdout).to match(/^logstash\s#{LOGSTASH_VERSION}/)
  end
end
