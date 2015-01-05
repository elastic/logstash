require "spec_helper"

require "logstash/config/grammar"
require "logstash/config/config_ast"

describe LogStashConfigParser do

  let(:parser) { LogStashConfigParser.new }
  let(:single_quote_config) { <<-CONFIG
                              input {
                                  example {
                                    'foo' => 'bar'
                                    test => { 'bar' => 'baz' }
                                  }
                              }
                              CONFIG
  }
  let(:empty_config)        { 'filter {}' }

  it "permits single-quoted attribute names" do
    config = parser.parse(single_quote_config)
    expect(config).not_to be_nil
  end

  it "permits empty plugin sections" do
    config = parser.parse(empty_config)
    expect(config).not_to be_nil
  end
end
