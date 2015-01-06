# config syntax tests
#

require "logstash/config/grammar"
require "logstash/config/config_ast"

describe LogStashConfigParser do
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
end
