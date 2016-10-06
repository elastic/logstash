# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Settings do
  let(:numeric_setting_name) { "number" }
  let(:numeric_setting) { LogStash::Setting.new(numeric_setting_name, Numeric, 1) }
  describe "#register" do
    context "if setting has already been registered" do
      before :each do
        subject.register(numeric_setting)
      end
      it "should raise an exception" do
        expect { subject.register(numeric_setting) }.to raise_error
      end
    end
    context "if setting hasn't been registered" do
      it "should not raise an exception" do
        expect { subject.register(numeric_setting) }.to_not raise_error
      end
    end
  end
  describe "#get_setting" do
    context "if setting has been registered" do
      before :each do
        subject.register(numeric_setting)
      end
      it "should return the setting" do
        expect(subject.get_setting(numeric_setting_name)).to eq(numeric_setting)
      end
    end
    context "if setting hasn't been registered" do
      it "should raise an exception" do
        expect { subject.get_setting(numeric_setting_name) }.to raise_error
      end
    end
  end
  describe "#get_subset" do
    let(:numeric_setting_1) { LogStash::Setting.new("num.1", Numeric, 1) }
    let(:numeric_setting_2) { LogStash::Setting.new("num.2", Numeric, 2) }
    let(:numeric_setting_3) { LogStash::Setting.new("num.3", Numeric, 3) }
    let(:string_setting_1) { LogStash::Setting.new("string.1", String, "hello") }
    before :each do
      subject.register(numeric_setting_1)
      subject.register(numeric_setting_2)
      subject.register(numeric_setting_3)
      subject.register(string_setting_1)
    end

    it "supports regex" do
      expect(subject.get_subset(/num/).get_setting("num.3")).to eq(numeric_setting_3)
      expect { subject.get_subset(/num/).get_setting("string.1") }.to raise_error
    end

    it "returns a copy of settings" do
      subset = subject.get_subset(/num/)
      subset.set("num.2", 1000)
      expect(subject.get("num.2")).to eq(2)
      expect(subset.get("num.2")).to eq(1000)
    end
  end

  describe "#validate_all" do
    subject { described_class.new }
    let(:numeric_setting_name) { "example" }
    let(:numeric_setting) { LogStash::Setting.new(numeric_setting_name, Numeric, 1, false) }

    before do
      subject.register(numeric_setting)
      subject.set_value(numeric_setting_name, value)
    end

    context "when any setting is invalid" do
      let(:value) { "some string" }

      it "should fail" do
        expect { subject.validate_all }.to raise_error
      end
    end

    context "when all settings are valid" do
      let(:value) { 123 }

      it "should succeed" do
        expect { subject.validate_all }.not_to raise_error
      end
    end
  end
end
