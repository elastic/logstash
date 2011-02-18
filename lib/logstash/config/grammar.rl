require "rubygems"
require "logstash/namespace"
require "ap" # TODO(sissel): Remove this.

%%{
  machine logstash_config;

  action mark {
    @tokenstack.push(p)
    #puts "Mark: #{self.line(string, p)}##{self.column(string, p)}"
  }

  action stack_numeric {
    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "numeric: #{token}"
    #puts "numeric?: #{string[startpos,50]}"
    #puts [startpos, endpos].join(",")
    @stack << token.to_i
  }

  action stack_string {
    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "string: #{token}"
    @stack << token
  }

  action stack_quoted_string {
    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos + 1 ... endpos - 1] # Skip quotations

    # Parse escapes.
    token.gsub(/\\./) { |m| return m[1,1] }
    puts "quotedstring: #{token}"
    @stack << token
  }

  action array_init {
    @array = []
    @stack << :array_init
  }

  action array_push {
    while @stack.last != :array_init
      @array.unshift @stack.pop
    end
    @stack.pop # pop :array_init

    @stack << @array
    #puts "array: #{@array.join(",")}"
  }

  action parameter_init {
    @parameters = Hash.new { |h,k| h[k] = [] }
  }

  action parameter {
    value = @stack.pop
    name = @stack.pop
    #puts "parameter: #{name} => #{value}"
    @parameters[name] << value
  }

  action component_implementation {
    @components ||= []
    name = @stack.pop
    #@components << { :name => name, :parameters => @parameters }
    @components << { name => @parameters }
  }

  action component_init {
    puts "current component: " + @stack.last
    @components = []
  }

  action component {
    name = @stack.pop
    ap name => @components
    #ap @stack
  }
    
  ws = ([ \t\n])** ;
  quoted_string = ( ( "\"" ( ( (any - [\\"\n]) | "\\" any )* ) "\"" ) |
                    ( "'" ( ( (any - [\\'\n]) | "\\" any )* ) "'" ) )
                  >mark %stack_quoted_string ;

  # TODO(sissel): Support floating point values?
  numeric = ( ("+" | "-")?  [0-9] [0-9]** ) >mark %stack_numeric;
  naked_string = ( [A-Za-z_] [A-Za-z0-9_]** ) >mark %stack_string ;
  string = ( quoted_string | naked_string ) ;

  array = ( "[" ws string ws ("," ws string ws)* "]" ) >array_init %array_push;
  parameter_value = ( numeric | string | array );
  parameter = ( string ws "=>" ws parameter_value ) %parameter ;
  parameters = ( parameter ( ws parameter )** ) >parameter_init ;

  # Statement:
  # component {
  #   component_implementation_name {
  #     bar => ...
  #     baz => ...
  #   }
  #   ...
  # }

  component_implementation = (
    naked_string ws "{" ws
      parameters
    ws "}"
  ) %component_implementation ; 

  component = (
    naked_string ws "{"
      >component_init
      ( ws component_implementation )**
    ws "}"
  ) %component ;

  statement = (ws component )* ;

  main := statement
          0 @{ puts "Failed" }
          $err { 
            # Compute line and column of the cursor (p)
            puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
          } ;
}%%

class LogStash::Config::Parser
  attr_accessor :eof

  def initialize
    # BEGIN RAGEL DATA
    %% write data;
    # END RAGEL DATA

    @tokenstack = Array.new
    @stack = Array.new

    @types = Hash.new { |h,k| h[k] = [] }
    @edges = []
  end

  def parse(string)
    data = string.unpack("c*")

    # BEGIN RAGEL INIT
    %% write init;
    # END RAGEL INIT

    begin 
      # BEGIN RAGEL EXEC 
      %% write exec;
      # END RAGEL EXEC
    rescue => e
      # Compute line and column of the cursor (p)
      $stderr.puts "Exception at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
      raise e
    end

    return cs
  end

  def line(str, pos)
    return str[0 .. pos].count("\n") + 1
  end

  def column(str, pos)
    return str[0 .. pos].split("\n").last.length
  end

end # class LogStash::Config::Parser

def parse(string)
  puts "result %s" % LogStash::Config::Parser.new.parse(string)
end

parse(File.open(ARGV[0]).read)
