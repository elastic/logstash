# encoding: utf-8
require "spec_helper"
require "logstash/config/validators/parameter_validator"
require "logstash/config/config_validator"

describe LogStash::Config::Validation do

  let(:config) do

    {"enable_metric"  => { :validate=>:boolean, :default=>true },
     "id"             => { :validate=>:string },
     "codec"          => { :validate=>:codec, :default=>"plain" },
     "size"           => { :validate=>:bytes, :required=>true },
     "files"          => { :validate=>:array, :required=>true }}
  end

  subject(:validator) { described_class.new(config, "plugin_type", "plugin_name") }


  describe "Validation of params" do

    it "should return false if there is an attribute not defined in the config" do
      params       = {"sized"=>100, "enable_metric"=>true, "codec"=>"plain"}
      valid_params, errors = validator.valid_params?(params)
      expect(valid_params).to eq(false)
      expect(errors).not_to be_empty
    end

    it "should return false if a required attribute is missing" do
      params = {"size"=>100, "enable_metric"=>true, "codec"=>"plain" }
      valid_params, errors = validator.valid_params?(params)
      expect(valid_params).to eq(false)
      expect(errors).not_to be_empty
    end

    it "should return true if all required parameters are defined" do
      params = {"size"=>100, "files" => ["foo"], "enable_metric"=>true, "codec"=>"plain"}
      expect(validator.valid_params?(params)).to eq([true, []])
    end
  end

  describe "Validation of values" do

    describe "String validation" do
      let(:config) do
        {"enable_metric"  => { :validate=>:boolean, :default=>true },
         "files"          => { :validate=>:string, :required=>true }}
      end

      it "should validate a single string as OK" do
        params = { "files" => "/foo/bar.txt" }
        expect(validator.valid_values?(params)).to eq([true, []])
      end

      it "should validate a single array as if a single String as OK" do
        params = { "files" => ["/foo/bar.txt"] }
        expect(validator.valid_values?(params)).to eq([true, []])
      end

      it "should fail with a non String" do
        params = { "files" => 123  }
        expect(validator.valid_values?(params)).to eq([false, ["Expected string, got 123"]])
      end

      it "should fail with a non String Array" do
        params = { "files" => [123] }
        expect(validator.valid_values?(params)).to eq([false, ["Expected string, got [123]"]])
      end

      it "should fail with a multi type array" do
        params = { "files" => ["Foo", 123] }
        expect(validator.valid_values?(params)).to eq([false, ["Expected string, got [\"Foo\", 123]"]])
      end
      it "should fail with a size > 1 array" do
        params = { "files" => ["Foo", "Bar"] }
        expect(validator.valid_values?(params)).to eq([false, ["Expected string, got [\"Foo\", \"Bar\"]"]])
      end
    end
  end
end
