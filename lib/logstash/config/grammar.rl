require "logstash/namespace"

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
    # TODO(sissel): Don't do 'to_i' here. Type coersion is the job of the
    # plugin and the validator.
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
    token.gsub(/\\./) { |m| m[1,1] }
    #puts "quotedstring: #{token}"
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
  }

  action parameter_init {
    # nothing
  }

  action parameter {
    value = @stack.pop
    name = @stack.pop
    #puts "parameter: #{name} => #{value}"
    if value.is_a?(Array)
      @parameters[name] += value
    else
      @parameters[name] << value
    end
  }

  action plugin {
    @components ||= []
    name = @stack.pop
    #@components << { :name => name, :parameters => @parameters }
    @components << { name => @parameters }
    @parameters = Hash.new { |h,k| h[k] = [] }
  }

  action component_init {
    @components = []
    @parameters = Hash.new { |h,k| h[k] = [] }
  }

  action component {
    name = @stack.pop
    @config ||= Hash.new { |h,k| h[k] = [] }
    @config[name] += @components
    #puts "Config component: #{name}"
  }

  #%{ e = @tokenstack.pop; puts "Comment: #{string[e ... p]}" };
  comment = "#" (any - [\n])* >mark ; 
  ws = ([ \t\n] | comment)** ;
  #ws = ([ \t\n])** ;

  # TODO(sissel): Support floating point values?
  numeric = ( ("+" | "-")?  [0-9] :>> [0-9]** ) >mark %stack_numeric;
  quoted_string = ( 
    ( "\"" ( ( (any - [\\"\n]) | "\\" any )* ) "\"" )
    | ( "'" ( ( (any - [\\'\n]) | "\\" any )* ) "'" ) 
  ) >mark %stack_quoted_string ;
  naked_string = ( [A-Za-z_] :>> [A-Za-z0-9_]* ) >mark %stack_string ;
  string = ( quoted_string | naked_string ) ;

  # TODO(sissel): allow use of this.
  regexp_literal = ( "/" ( ( (any - [\\'\n]) | "\\" any )* ) "/" )  ;

  array = ( "[" ws ( string | numeric ) ws ("," ws (string | numeric ) ws)* "]" ) >array_init %array_push;
  parameter_value = ( numeric | string | array );
  parameter = ( string ws "=>" ws parameter_value ) %parameter ;
  parameters = ( parameter ( ws parameter )** ) >parameter_init ;

  # Statement:
  # component {
  #   plugin_name {
  #     bar => ...
  #     baz => ...
  #   }
  #   ...
  # }

  plugin = (
    (
      naked_string ws "{" ws
        parameters
      ws "}"
    ) | ( 
      naked_string ws "{" ws "}" 
    )
  ) %plugin ; 

  component = (
    naked_string ws "{"
      >component_init
      ( ws plugin )**
    ws "}"
  ) %component ;

  config = (ws component? )** ;

  main := config %{ puts "END" }
          $err { 
            # Compute line and column of the cursor (p)
            $stderr.puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
            # TODO(sissel): Note what we were expecting?
          } ;
}%%

class LogStash::Config::Grammar
  attr_accessor :eof
  attr_accessor :config

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
    # TODO(sissel): Due to a bug in my parser, we need one trailing whitespace
    # at the end of the string. I'll fix this later.
    string += "\n"

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
      raise e
    end

    if cs < self.logstash_config_first_final
      $stderr.puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
      raise "Invalid Configuration. Check syntax of config file."
    end
    return cs
  end # def parse

  def line(str, pos)
    return str[0 .. pos].count("\n") + 1
  end

  def column(str, pos)
    return str[0 .. pos].split("\n").last.length
  end
end # class LogStash::Config::Grammar

#def parse(string)
  #cfgparser = LogStash::Config::Grammar.new
  #result = cfgparser.parse(string)
  #puts "result %s" % result
  #ap cfgparser.config
#end

#parse(File.open(ARGV[0]).read)
