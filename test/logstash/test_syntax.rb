require "rubygems"
require "test/unit"

class SyntaxCheckTest < Test::Unit::TestCase
  def setup
    @dir = File.dirname(__FILE__)
  end

  def test_ruby_syntax
    Dir["#{@dir}/../**/*.rb"].each do |path|
      output = %x{ruby -c #{path} 2>&1}
      assert_equal(0, $?.exitstatus, "Syntax error for #{path}: #{output}")
    end
  end
end
