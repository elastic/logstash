# encoding: utf-8
require "spec_helper"
require "logstash/config/validators/parameter_validator"
require "logstash/config/config_validator"

describe "validators" do

  describe LogStash::Config::TypeValidators::String do

    it "should return true for a valid String" do
      expect(subject.valid?("foo")).to eq(true)
    end

    it "should return true for a valid string array" do
      expect(subject.valid?(["foo"])).to eq(true)
    end

    it "shuold return false for a non string value" do
      expect(subject.valid?(1234)).to   eq(false)
      expect(subject.valid?([1234])).to eq(false)
    end

end


  describe LogStash::Config::TypeValidators::Boolean do

    it "should return true for a valid Boolean" do
      ["true", "false", true, false].each do |type|
        expect(subject.valid?(type)).to eq(true)
      end
    end

    it "should return false for a non valid Boolean" do
      expect(subject.valid?("truethy")).to eq(false)
    end
  end

  describe LogStash::Config::TypeValidators::Bytes do
   
    it "should return true for a valid Bytes" do
      expect(subject.valid?("1 kb")).to eq(true)
    end

    it "should return false for a invalid Bytes" do
      expect(subject.valid?("-1 kb")).to eq(false)
    end

  end

  describe LogStash::Config::Validators::NameValidator do

    let(:config) do

      {"enable_metric"  => { :validate=>:boolean, :default=>true },
       "id"             => { :validate=>:string },
       "codec"          => { :validate=>:codec, :default=>"plain" },
       "size"           => { :validate=>:bytes, :required=>true },
       "files"          => { :validate=>:array, :required=>true }
      }
    end

    let(:params) {
      {"sized"=>100, "enable_metric"=>true, "debug"=>false, "codec"=>"plain", "add_field"=>{}}
    }

    subject(:validator) { described_class.new(config, "plugin_type", "plugin_name") }

    it "should return false if the key is not present" do
      expect(validator.valid?("not-preset-key", 100)).to eq( [false, "Unknown setting 'not-preset-key' for plugin_name"])
    end

  end

  describe LogStash::Config::Validators::ExistValueValidator do

    let(:config) do
      {"enable_metric"  => { :validate=>:boolean, :default=>true },
       "id"             => { :validate=>:string },
       "codec"          => { :validate=>:codec, :default=>"plain" },
       "size"           => { :validate=>:bytes, :required=>true },
       "files"          => { :validate=>:array, :required=>true }}
    end

    let(:params) {
      {"sized"=>100, "enable_metric"=>true, "debug"=>false, "codec"=>"plain", "add_field"=>{}}
    }

    subject(:validator) { described_class.new(config, "plugin_type", "plugin_name") }

    it "should return false if the required value is missing" do
      expect(validator.valid?("size", nil)).to eq([false, "Missing a required setting for the plugin_name plugin_type plugin:\n\n  plugin_type {\n    plugin_name {\n      size => # SETTING MISSING\n      ...\n    }\n  }"])
    end

    it "should return true if the required value is present" do
      expect(validator.valid?("size", 100)).to eq([true, ""])
    end

    it "should return true if the value is not required" do
      expect(validator.valid?("codec", "json")).to eq([true, ""])
    end
  end
end
