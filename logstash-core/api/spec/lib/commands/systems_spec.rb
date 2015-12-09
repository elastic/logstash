# encoding: utf-8
require_relative "../../spec_helper"
require "app/system/info_command"

describe LogStash::Api::SystemInfoCommand do

  let(:service) { double("snapshot-service") }

  subject { described_class.new(service) }

  context "#schema" do
    let(:report) { subject.run }

    it "return a list of plugins" do
      expect(report).to include("plugins" => { "count" => a_kind_of(Fixnum), "list" => a_kind_of(Array)})
    end

    it "include version information" do
      expect(report).to include("version" => a_kind_of(String))
    end

    it "include hostname information" do
      expect(report).to include("host_name" => a_kind_of(String))
    end

  end
end
