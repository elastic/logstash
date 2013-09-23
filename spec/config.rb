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

    reject { config }.nil?
  end

  it "should permit empty plugin sections" do
    parser = LogStashConfigParser.new
    config = parser.parse(%q(
      filter {
      }
    ))

    reject { config }.nil?
  end
end
