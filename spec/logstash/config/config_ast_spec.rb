# encoding: utf-8
# config syntax tests
#
require "spec_helper"
require "logstash/config/grammar"
require "logstash/config/config_ast"

describe LogStashConfigParser do
  context '#parse' do
    context "valid configuration" do
      it "should permit single-quoted attribute names" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input {
            example {
              'foo' => 'bar'
              test => { 'bar' => 'baz' }
            }
          }
          ))

        expect(config).not_to be_nil
      end

      it "should permit empty plugin sections" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          filter {
          }
          ))

        expect(config).not_to be_nil
      end

      it 'permits hash to contains array' do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input{
            example {
              match => {
                "message"=> ["pattern1", "pattern2", "pattern3"]
              }
            }
          }))
        expect(config).not_to be_nil
      end
    end
  end

  context "#compile" do
    context "if with multiline conditionals" do
      let(:config) { <<-CONFIG }
        filter {
          if [something]
             or [anotherthing]
             or [onemorething] {
          }
        }
      CONFIG
      subject { LogStashConfigParser.new }
         
      it "should compile successfully" do
        result = subject.parse(config)
        expect(result).not_to(be_nil)
        expect { eval(result.compile) }.not_to(raise_error)
      end
    end

    context "elsif with multiline conditionals" do
      let(:config) { <<-CONFIG }
        filter {
          if [notathing] {
          } else if [something]
                or [anotherthing]
                or [onemorething] {
          }
        }
      CONFIG
      subject { LogStashConfigParser.new }
         
      it "should compile successfully" do
        result = subject.parse(config)
        expect(result).not_to(be_nil)
        expect { eval(result.compile) }.not_to(raise_error)
      end
    end


    context "invalid configuration" do
      it "rejects duplicate hash key" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input {
            example {
              match => {
                "message"=> "pattern1"
                "message"=> "pattern2"
                "message"=> "pattern3"
              }
            }
          }
        ))

        expect { config.compile }.to raise_error(LogStash::ConfigurationError, /Duplicate keys found in your configuration: \["message"\]/)
      end

      it "rejects duplicate keys in nested hash" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input {
            example {
              match => {
                "message"=> "pattern1"
                "more" => {
                  "cool" => true
                  "cool" => true
                }
              }
            }
          }
        ))

        expect { config.compile }.to raise_error(LogStash::ConfigurationError, /Duplicate keys found in your configuration: \["cool"\]/)
      end

      it "rejects a key with multiple double quotes" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input {
            example {
              match => {
                "message"=> "pattern1"
                ""more"" => {
                  "cool" => true
                  "cool" => true
                }
              }
            }
          }
        ))

        expect(config).to be_nil
      end
    end
  end

  context "when using two plugin sections of the same type" do
    let(:pipeline_klass) do
      Class.new do
        def initialize(config)
          grammar = LogStashConfigParser.new
          @config = grammar.parse(config)
          @code = @config.compile
          eval(@code)
        end
        def plugin(*args);end
      end
    end
    context "(filters)" do
      let(:config_string) {
        "input { generator { } }
         filter { filter1 { } }
         filter { filter1 { } }
         output { output1 { } }"
      }


      it "should create a pipeline with both sections" do
        generated_objects = pipeline_klass.new(config_string).instance_variable_get("@generated_objects")
        filters = generated_objects.keys.map(&:to_s).select {|obj_name| obj_name.match(/^filter.+?_\d+$/) }
        expect(filters.size).to eq(2)
      end
    end

    context "(filters)" do
      let(:config_string) {
        "input { generator { } }
         output { output1 { } }
         output { output1 { } }"
      }


      it "should create a pipeline with both sections" do
        generated_objects = pipeline_klass.new(config_string).instance_variable_get("@generated_objects")
        outputs = generated_objects.keys.map(&:to_s).select {|obj_name| obj_name.match(/^output.+?_\d+$/) }
        expect(outputs.size).to eq(2)
      end
    end
  end
  context "when creating two instances of the same configuration" do

    let(:config_string) {
      "input { generator { } }
       filter {
         if [type] == 'test' { filter1 { } }
       }
       output {
         output1 { }
       }"
    }

    let(:pipeline_klass) do
      Class.new do
        def initialize(config)
          grammar = LogStashConfigParser.new
          @config = grammar.parse(config)
          @code = @config.compile
          eval(@code)
        end
        def plugin(*args);end
      end
    end

    describe "generated conditional functionals" do
      it "should be created per instance" do
        instance_1 = pipeline_klass.new(config_string)
        instance_2 = pipeline_klass.new(config_string)
        generated_method_1 = instance_1.instance_variable_get("@generated_objects")[:cond_func_1]
        generated_method_2 = instance_2.instance_variable_get("@generated_objects")[:cond_func_1]
        expect(generated_method_1).to_not be(generated_method_2)
      end
    end
  end
end
