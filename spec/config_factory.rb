require 'pp'

## Example
##
## ConfigFactory.filter.
#               add_field("always" => "awesome").
#               if("[foo] == 'bar'").
#               add_field("hello" => "world").
#               elseif("[bar] == 'baz'").
#               add_field("fancy" => "pants").
#               else.
#               add_field("free" => "hugs")
#
#  ConfigFactory.filter.
#                if("[foo] in [foobar]").add_tag("field in field").
#                if("[foo] in 'foo'").add_tag("field in string").
#                if("'hello' in [greeting]").add_tag("string in field")
#                if("!('foo' in ['hello', 'world'])").add_tag("shouldexist")
#

module Conditionals

  def if(criteria)
    stack.push "if #{criteria} {"
    self
  end

  def elseif(criteria)
    stack.push "} else if #{criteria} {"
    self
  end

  def else
    stack.push "} else {"
    self
  end

  def endif
    stack.push "}"
    self
  end
end

class Filter

  include Conditionals

  attr_reader :stack

  def initialize
    @stack = []
  end


  def clones(*fields)
    stack.push "clone { clones => #{fields} }"
    self
  end

  def add_field(field)
    stack.push "mutate { add_field => #{field} }"
    self
  end

  def add_tag(tag)
    stack.push "mutate { add_tag => '#{tag}'  }"
    self
  end

  def %(patterns)
    to_s % patterns
  end

  def to_s
    "filter { #{stack.join(' ')} }"
  end
end

class ConfigFactory

  def self.filter
    Filter.new
  end

end
