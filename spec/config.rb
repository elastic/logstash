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

module LogStash::Config
  class Dummy < LogStash::Pipeline
    attr_reader :inputs, :filters, :outputs

    def initialize(configstr)
      super
      @inputs = plugins_hash(@inputs)
      @filters = plugins_hash(@filters)
      @outputs = plugins_hash(@outputs)
    end

    def self.parsed(config_value_str)
      self.new("input { m { k => #{config_value_str} } }").
        inputs['m'].first.first['k']
    end

    private

    def plugin(plugin_type, name, *args)
      [ name, args ]
    end

    def plugins_hash(plugins_list)
      rv = {}
      plugins_list.each do |name, args|
        (rv[name] ||= []) << args
      end
      rv
    end
  end


  module AST
    describe Value do
      it "parses `null` as `nil`" do
        insist { Dummy.parsed('null') }.nil?
      end

      it "parses `true` as `true`" do
        insist { Dummy.parsed('true') } == true
      end

      it "parses `false` as `false`" do
        insist { Dummy.parsed('false') } == false
      end

      it "parses double-quoted strings using JSON to do the details" do
        [ "foo",
          "foo bar",
          'foo " bar',
          "foo\\\"bar'baz",
          "\\",
          "\"",
          ::File.read(__FILE__),
        ].each do |test_value|
          insist { Dummy.parsed(test_value.to_json) } == test_value
        end
      end

      it "passes JSON unit tests" do
        # This also ensures proper parsing of numbers & strings with
        # all the quoting corner cases.
        Dir[ ::File.join(Gem::Specification.find_by_name('json').gem_dir,
            'tests', 'fixtures', 'pass*.json') ].
          map { |fixture| ::File.read(fixture) }.
          each { |jsonstr| insist { Dummy.parsed(jsonstr) } == JSON[jsonstr] }
      end

      it "handles nested hashes" do
        insist { Dummy.parsed("{ foo => 1, bar => { baz => 2, quux => 3 } }") } == {
          'foo' => 1,
          'bar' => {
            'baz' => 2,
            'quux' => 3 }}
      end

      it "parses single-quoted string like POSIX shell" do
        insist { Dummy.parsed("'foo'") } == "foo"
        insist { Dummy.parsed("'fo\\o'") } == "fo\\o"
        insist { Dummy.parsed("'foo\\'") } == "foo\\"
      end

    end
  end
end
