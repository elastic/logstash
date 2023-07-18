# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# config syntax tests
require "spec_helper"
require "logstash/config/grammar"
require "logstash/config/config_ast"

describe LogStashConfigParser do
  let(:settings) { mock_settings({}) }

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

      it "supports octal literals" do
        parser = LogStashConfigParser.new
        config = parser.parse(%q(
          input {
            example {
              foo => 010
            }
          }
        ))

        compiled_number = eval(config.recursive_select(LogStash::Config::AST::Number).first.compile)

        expect(compiled_number).to be == 8
      end
    end

    context "when config.support_escapes" do
      let(:parser) { LogStashConfigParser.new }

      let(:processed_value)  { 'The computer says, "No"' }

      let(:config) {
        parser.parse(%q(
          input {
            foo {
              bar => "The computer says, \"No\""
            }
          }
        ))
      }

      let(:compiled_string) { eval(config.recursive_select(LogStash::Config::AST::String).first.compile) }

      before do
        config.process_escape_sequences = escapes
      end

      context "is enabled" do
        let(:escapes) { true }

        it "should process escape sequences" do
          expect(compiled_string).to be == processed_value
        end
      end

      context "is false" do
        let(:escapes) { false }

        it "should not process escape sequences" do
          expect(compiled_string).not_to be == processed_value
        end
      end
    end
  end

  context "when using two plugin sections of the same type" do
    let(:pipeline_klass) do
      Class.new do
        def initialize(config, settings)
          grammar = LogStashConfigParser.new
          @config = grammar.parse(config)
          @code = @config.compile
          eval(@code)
        end

        def plugin(*args); end
        def line_to_source(*args); end
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
        generated_objects = pipeline_klass.new(config_string, settings).instance_variable_get("@generated_objects")
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
        generated_objects = pipeline_klass.new(config_string, settings).instance_variable_get("@generated_objects")
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
        def initialize(config, settings)
          grammar = LogStashConfigParser.new
          @config = grammar.parse(config)
          @code = @config.compile
          eval(@code)
        end

        def plugin(*args); end
        def line_to_source(*args); end
      end
    end

    describe "generated conditional functionals" do
      it "should be created per instance" do
        instance_1 = pipeline_klass.new(config_string, settings)
        instance_2 = pipeline_klass.new(config_string, settings)
        generated_method_1 = instance_1.instance_variable_get("@generated_objects")[:cond_func_1]
        generated_method_2 = instance_2.instance_variable_get("@generated_objects")[:cond_func_1]
        expect(generated_method_1).to_not be(generated_method_2)
      end
    end
  end
end
