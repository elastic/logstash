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
end
