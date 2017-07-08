# encoding: utf-8
require "logstash/modules/logstash_config"

describe LogStash::Modules::LogStashConfig do
  let(:mod) { instance_double("Modules", :directory => Stud::Temporary.directory, :module_name => "testing") }
  let(:settings) { {"var.logstash.testing.pants" => "fancy" }}
  subject { described_class.new(mod, settings) }

  describe "configured inputs" do
    context "when no inputs is send" do
      it "returns the default" do
        expect(subject.configured_inputs(["kafka"])).to include("kafka")
      end
    end

    context "when inputs are send" do
      let(:settings) { { "var.inputs" => "tcp" } }

      it "returns the configured inputs" do
        expect(subject.configured_inputs(["kafka"])).to include("tcp")
      end

      context "when alias is specified" do
        let(:settings) { { "var.inputs" => "smartconnector" } }

        it "returns the configured inputs" do
          expect(subject.configured_inputs(["kafka"], { "smartconnector" => "tcp"  })).to include("tcp", "smartconnector")
        end
      end
    end
  end

  describe "array to logstash array string" do
    it "return an escaped string" do
      expect(subject.array_to_string(["hello", "ninja"])).to eq("['hello', 'ninja']")
    end
  end

  describe "alias modules options" do
    let(:alias_table) do
      { "var.logstash.testing" => "var.logstash.better" }
    end

    before do
      subject.alias_settings_keys!(alias_table)
    end

    it "allow to retrieve settings" do
      expect(subject.setting("var.logstash.better.pants", "dont-exist")).to eq("fancy")
    end

    it "allow to retrieve settings with the original name" do
      expect(subject.setting("var.logstash.testing.pants", "dont-exist")).to eq("fancy")
    end
  end
end
