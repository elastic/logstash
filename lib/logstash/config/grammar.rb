
# line 1 "grammar.rl"
require "logstash/namespace"


# line 153 "grammar.rl"


class LogStash::Config::Grammar
  attr_accessor :eof
  attr_accessor :config

  def initialize
    # BEGIN RAGEL DATA
    
# line 17 "grammar.rb"
class << self
	attr_accessor :_logstash_config_actions
	private :_logstash_config_actions, :_logstash_config_actions=
end
self._logstash_config_actions = [
	0, 1, 0, 1, 1, 1, 2, 1, 
	3, 1, 4, 1, 8, 1, 9, 1, 
	10, 1, 11, 1, 12, 2, 0, 11, 
	2, 1, 7, 2, 2, 7, 2, 2, 
	9, 2, 3, 7, 2, 5, 7, 2, 
	6, 0, 2, 8, 0, 2, 10, 0, 
	2, 10, 11, 3, 1, 7, 0, 3, 
	2, 7, 0, 3, 3, 7, 0, 3, 
	5, 7, 0
]

class << self
	attr_accessor :_logstash_config_key_offsets
	private :_logstash_config_key_offsets, :_logstash_config_key_offsets=
end
self._logstash_config_key_offsets = [
	0, 0, 13, 19, 21, 23, 34, 36, 
	38, 51, 57, 59, 61, 74, 78, 84, 
	90, 92, 94, 95, 112, 116, 129, 142, 
	144, 146, 150, 150, 163, 174, 174, 176, 
	178, 182, 182, 184, 199, 214, 231, 235, 
	242, 249, 251, 253, 269, 271, 273, 277, 
	277, 279, 288, 301, 315, 315, 317, 319, 
	319, 321, 323, 333, 335, 337
]

class << self
	attr_accessor :_logstash_config_trans_keys
	private :_logstash_config_trans_keys, :_logstash_config_trans_keys=
end
self._logstash_config_trans_keys = [
	13, 32, 35, 95, 123, 9, 10, 48, 
	57, 65, 90, 97, 122, 13, 32, 35, 
	123, 9, 10, 10, 13, 10, 13, 13, 
	32, 35, 95, 125, 9, 10, 65, 90, 
	97, 122, 10, 13, 10, 13, 13, 32, 
	35, 95, 123, 9, 10, 48, 57, 65, 
	90, 97, 122, 13, 32, 35, 123, 9, 
	10, 10, 13, 10, 13, 13, 32, 34, 
	35, 39, 95, 125, 9, 10, 65, 90, 
	97, 122, 10, 13, 34, 92, 13, 32, 
	35, 61, 9, 10, 13, 32, 35, 61, 
	9, 10, 10, 13, 10, 13, 62, 13, 
	32, 34, 35, 39, 43, 45, 91, 95, 
	9, 10, 48, 57, 65, 90, 97, 122, 
	10, 13, 34, 92, 13, 32, 34, 35, 
	39, 95, 125, 9, 10, 65, 90, 97, 
	122, 13, 32, 34, 35, 39, 95, 125, 
	9, 10, 65, 90, 97, 122, 10, 13, 
	10, 13, 10, 13, 39, 92, 13, 32, 
	35, 61, 95, 9, 10, 48, 57, 65, 
	90, 97, 122, 13, 32, 35, 95, 125, 
	9, 10, 65, 90, 97, 122, 10, 13, 
	10, 13, 10, 13, 39, 92, 48, 57, 
	13, 32, 34, 35, 39, 95, 125, 9, 
	10, 48, 57, 65, 90, 97, 122, 13, 
	32, 34, 35, 39, 95, 125, 9, 10, 
	48, 57, 65, 90, 97, 122, 13, 32, 
	34, 35, 39, 43, 45, 93, 95, 9, 
	10, 48, 57, 65, 90, 97, 122, 10, 
	13, 34, 92, 13, 32, 35, 44, 93, 
	9, 10, 13, 32, 35, 44, 93, 9, 
	10, 10, 13, 10, 13, 13, 32, 34, 
	35, 39, 43, 45, 95, 9, 10, 48, 
	57, 65, 90, 97, 122, 10, 13, 10, 
	13, 10, 13, 39, 92, 48, 57, 13, 
	32, 35, 44, 93, 9, 10, 48, 57, 
	13, 32, 34, 35, 39, 95, 125, 9, 
	10, 65, 90, 97, 122, 13, 32, 35, 
	44, 93, 95, 9, 10, 48, 57, 65, 
	90, 97, 122, 10, 13, 10, 13, 10, 
	13, 10, 13, 13, 32, 35, 95, 9, 
	10, 65, 90, 97, 122, 10, 13, 10, 
	13, 13, 32, 35, 95, 9, 10, 65, 
	90, 97, 122, 0
]

class << self
	attr_accessor :_logstash_config_single_lengths
	private :_logstash_config_single_lengths, :_logstash_config_single_lengths=
end
self._logstash_config_single_lengths = [
	0, 5, 4, 2, 2, 5, 2, 2, 
	5, 4, 2, 2, 7, 4, 4, 4, 
	2, 2, 1, 9, 4, 7, 7, 2, 
	2, 4, 0, 5, 5, 0, 2, 2, 
	4, 0, 0, 7, 7, 9, 4, 5, 
	5, 2, 2, 8, 2, 2, 4, 0, 
	0, 5, 7, 6, 0, 2, 2, 0, 
	2, 2, 4, 2, 2, 4
]

class << self
	attr_accessor :_logstash_config_range_lengths
	private :_logstash_config_range_lengths, :_logstash_config_range_lengths=
end
self._logstash_config_range_lengths = [
	0, 4, 1, 0, 0, 3, 0, 0, 
	4, 1, 0, 0, 3, 0, 1, 1, 
	0, 0, 0, 4, 0, 3, 3, 0, 
	0, 0, 0, 4, 3, 0, 0, 0, 
	0, 0, 1, 4, 4, 4, 0, 1, 
	1, 0, 0, 4, 0, 0, 0, 0, 
	1, 2, 3, 4, 0, 0, 0, 0, 
	0, 0, 3, 0, 0, 3
]

class << self
	attr_accessor :_logstash_config_index_offsets
	private :_logstash_config_index_offsets, :_logstash_config_index_offsets=
end
self._logstash_config_index_offsets = [
	0, 0, 10, 16, 19, 22, 31, 34, 
	37, 47, 53, 56, 59, 70, 75, 81, 
	87, 90, 93, 95, 109, 114, 125, 136, 
	139, 142, 147, 148, 158, 167, 168, 171, 
	174, 179, 180, 182, 194, 206, 220, 225, 
	232, 239, 242, 245, 258, 261, 264, 269, 
	270, 272, 280, 291, 302, 303, 306, 309, 
	310, 313, 316, 324, 327, 330
]

class << self
	attr_accessor :_logstash_config_trans_targs
	private :_logstash_config_trans_targs, :_logstash_config_trans_targs=
end
self._logstash_config_trans_targs = [
	2, 2, 3, 1, 5, 2, 1, 1, 
	1, 0, 2, 2, 3, 5, 2, 0, 
	2, 2, 4, 2, 2, 4, 5, 5, 
	6, 8, 61, 5, 8, 8, 0, 5, 
	5, 7, 5, 5, 7, 9, 9, 10, 
	8, 12, 9, 8, 8, 8, 0, 9, 
	9, 10, 12, 9, 0, 9, 9, 11, 
	9, 9, 11, 12, 12, 13, 56, 25, 
	27, 28, 12, 27, 27, 0, 0, 0, 
	14, 55, 13, 15, 15, 16, 18, 15, 
	0, 15, 15, 16, 18, 15, 0, 15, 
	15, 17, 15, 15, 17, 19, 0, 19, 
	19, 20, 30, 32, 34, 34, 37, 36, 
	19, 35, 36, 36, 0, 0, 0, 21, 
	29, 20, 22, 22, 13, 23, 25, 27, 
	28, 22, 27, 27, 0, 22, 22, 13, 
	23, 25, 27, 28, 22, 27, 27, 0, 
	22, 22, 24, 22, 22, 24, 0, 0, 
	14, 26, 25, 25, 15, 15, 16, 18, 
	27, 15, 27, 27, 27, 0, 5, 5, 
	6, 8, 61, 5, 8, 8, 0, 20, 
	19, 19, 31, 19, 19, 31, 0, 0, 
	21, 33, 32, 32, 35, 0, 22, 22, 
	13, 23, 25, 27, 28, 22, 35, 27, 
	27, 0, 22, 22, 13, 23, 25, 36, 
	28, 22, 36, 36, 36, 0, 37, 37, 
	38, 53, 46, 48, 48, 50, 51, 37, 
	49, 51, 51, 0, 0, 0, 39, 52, 
	38, 40, 40, 41, 43, 50, 40, 0, 
	40, 40, 41, 43, 50, 40, 0, 40, 
	40, 42, 40, 40, 42, 43, 43, 38, 
	44, 46, 48, 48, 51, 43, 49, 51, 
	51, 0, 43, 43, 45, 43, 43, 45, 
	0, 0, 39, 47, 46, 46, 49, 0, 
	40, 40, 41, 43, 50, 40, 49, 0, 
	22, 22, 13, 23, 25, 27, 28, 22, 
	27, 27, 0, 40, 40, 41, 43, 50, 
	51, 40, 51, 51, 51, 0, 38, 37, 
	37, 54, 37, 37, 54, 13, 12, 12, 
	57, 12, 12, 57, 58, 58, 59, 1, 
	58, 1, 1, 0, 58, 58, 60, 58, 
	58, 60, 58, 58, 59, 1, 58, 1, 
	1, 0, 0
]

class << self
	attr_accessor :_logstash_config_trans_actions
	private :_logstash_config_trans_actions, :_logstash_config_trans_actions=
end
self._logstash_config_trans_actions = [
	5, 5, 5, 0, 30, 5, 0, 0, 
	0, 19, 0, 0, 0, 13, 0, 19, 
	1, 1, 1, 0, 0, 0, 0, 0, 
	0, 1, 0, 0, 1, 1, 19, 1, 
	1, 1, 0, 0, 0, 5, 5, 5, 
	0, 5, 5, 0, 0, 0, 19, 0, 
	0, 0, 0, 0, 19, 1, 1, 1, 
	0, 0, 0, 0, 0, 39, 0, 39, 
	39, 0, 0, 39, 39, 19, 19, 19, 
	0, 0, 0, 7, 7, 7, 7, 7, 
	19, 0, 0, 0, 0, 0, 19, 1, 
	1, 1, 0, 0, 0, 0, 19, 0, 
	0, 1, 0, 1, 1, 1, 9, 1, 
	0, 1, 1, 1, 19, 19, 19, 0, 
	0, 0, 33, 33, 59, 33, 59, 59, 
	33, 33, 59, 59, 19, 0, 0, 1, 
	0, 1, 1, 0, 0, 1, 1, 19, 
	1, 1, 1, 0, 0, 0, 19, 19, 
	0, 0, 0, 0, 5, 5, 5, 5, 
	0, 5, 0, 0, 0, 19, 11, 11, 
	11, 42, 11, 11, 42, 42, 19, 0, 
	1, 1, 1, 0, 0, 0, 19, 19, 
	0, 0, 0, 0, 0, 19, 24, 24, 
	51, 24, 51, 51, 24, 24, 0, 51, 
	51, 19, 27, 27, 55, 27, 55, 0, 
	27, 27, 0, 0, 0, 19, 0, 0, 
	1, 0, 1, 1, 1, 0, 1, 0, 
	1, 1, 1, 19, 19, 19, 0, 0, 
	0, 7, 7, 7, 7, 7, 7, 19, 
	0, 0, 0, 0, 0, 0, 19, 1, 
	1, 1, 0, 0, 0, 0, 0, 1, 
	0, 1, 1, 1, 1, 0, 1, 1, 
	1, 19, 1, 1, 1, 0, 0, 0, 
	19, 19, 0, 0, 0, 0, 0, 19, 
	3, 3, 3, 3, 3, 3, 0, 19, 
	36, 36, 63, 36, 63, 63, 36, 36, 
	63, 63, 19, 5, 5, 5, 5, 5, 
	0, 5, 0, 0, 0, 19, 0, 1, 
	1, 1, 0, 0, 0, 0, 1, 1, 
	1, 0, 0, 0, 0, 0, 0, 1, 
	0, 1, 1, 19, 1, 1, 1, 0, 
	0, 0, 15, 15, 15, 45, 15, 45, 
	45, 19, 0
]

class << self
	attr_accessor :_logstash_config_eof_actions
	private :_logstash_config_eof_actions, :_logstash_config_eof_actions=
end
self._logstash_config_eof_actions = [
	0, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 19, 19, 19, 19, 19, 19, 
	19, 19, 17, 21, 17, 48
]

class << self
	attr_accessor :logstash_config_start
end
self.logstash_config_start = 58;
class << self
	attr_accessor :logstash_config_first_final
end
self.logstash_config_first_final = 58;
class << self
	attr_accessor :logstash_config_error
end
self.logstash_config_error = 0;

class << self
	attr_accessor :logstash_config_en_main
end
self.logstash_config_en_main = 58;


# line 162 "grammar.rl"
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
    
# line 299 "grammar.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = logstash_config_start
end

# line 181 "grammar.rl"
    # END RAGEL INIT

    begin 
      # BEGIN RAGEL EXEC 
      
# line 312 "grammar.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	_goto_level = 0
	_resume = 10
	_eof_trans = 15
	_again = 20
	_test_eof = 30
	_out = 40
	while true
	_trigger_goto = false
	if _goto_level <= 0
	if p == pe
		_goto_level = _test_eof
		next
	end
	if cs == 0
		_goto_level = _out
		next
	end
	end
	if _goto_level <= _resume
	_keys = _logstash_config_key_offsets[cs]
	_trans = _logstash_config_index_offsets[cs]
	_klen = _logstash_config_single_lengths[cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if data[p].ord < _logstash_config_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p].ord > _logstash_config_trans_keys[_mid]
	           _lower = _mid + 1
	        else
	           _trans += (_mid - _keys)
	           _break_match = true
	           break
	        end
	     end # loop
	     break if _break_match
	     _keys += _klen
	     _trans += _klen
	  end
	  _klen = _logstash_config_range_lengths[cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if data[p].ord < _logstash_config_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p].ord > _logstash_config_trans_keys[_mid+1]
	          _lower = _mid + 2
	        else
	          _trans += ((_mid - _keys) >> 1)
	          _break_match = true
	          break
	        end
	     end # loop
	     break if _break_match
	     _trans += _klen
	  end
	end while false
	cs = _logstash_config_trans_targs[_trans]
	if _logstash_config_trans_actions[_trans] != 0
		_acts = _logstash_config_trans_actions[_trans]
		_nacts = _logstash_config_actions[_acts]
		_acts += 1
		while _nacts > 0
			_nacts -= 1
			_acts += 1
			case _logstash_config_actions[_acts - 1]
when 0 then
# line 6 "grammar.rl"
		begin

    @tokenstack.push(p)
    #puts "Mark: #{self.line(string, p)}##{self.column(string, p)}"
  		end
when 1 then
# line 11 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "numeric: #{token}"
    #puts "numeric?: #{string[startpos,50]}"
    #puts [startpos, endpos].join(",")
    # TODO(sissel): Don't do 'to_i' here. Type coersion is the job of the
    # plugin and the validator.
    @stack << token.to_i
  		end
when 2 then
# line 23 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "string: #{token}"
    @stack << token
  		end
when 3 then
# line 31 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos + 1 ... endpos - 1] # Skip quotations

    # Parse escapes.
    token.gsub(/\\./) { |m| m[1,1] }
    #puts "quotedstring: #{token}"
    @stack << token
  		end
when 4 then
# line 42 "grammar.rl"
		begin

    @array = []
    @stack << :array_init
  		end
when 5 then
# line 47 "grammar.rl"
		begin

    while @stack.last != :array_init
      @array.unshift @stack.pop
    end
    @stack.pop # pop :array_init

    @stack << @array
  		end
when 6 then
# line 56 "grammar.rl"
		begin

    # nothing
  		end
when 7 then
# line 60 "grammar.rl"
		begin

    value = @stack.pop
    name = @stack.pop
    #puts "parameter: #{name} => #{value}"
    if value.is_a?(Array)
      @parameters[name] += value
    else
      @parameters[name] << value
    end
  		end
when 8 then
# line 71 "grammar.rl"
		begin

    @components ||= []
    name = @stack.pop
    #@components << { :name => name, :parameters => @parameters }
    @components << { name => @parameters }
    @parameters = Hash.new { |h,k| h[k] = [] }
  		end
when 9 then
# line 79 "grammar.rl"
		begin

    @components = []
    @parameters = Hash.new { |h,k| h[k] = [] }
  		end
when 10 then
# line 84 "grammar.rl"
		begin

    name = @stack.pop
    @config ||= Hash.new { |h,k| h[k] = [] }
    @config[name] += @components
    #puts "Config component: #{name}"
  		end
when 12 then
# line 148 "grammar.rl"
		begin
 
            # Compute line and column of the cursor (p)
            $stderr.puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
            # TODO(sissel): Note what we were expecting?
          		end
# line 507 "grammar.rb"
			end # action switch
		end
	end
	if _trigger_goto
		next
	end
	end
	if _goto_level <= _again
	if cs == 0
		_goto_level = _out
		next
	end
	p += 1
	if p != pe
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if p == eof
	__acts = _logstash_config_eof_actions[cs]
	__nacts =  _logstash_config_actions[__acts]
	__acts += 1
	while __nacts > 0
		__nacts -= 1
		__acts += 1
		case _logstash_config_actions[__acts - 1]
when 0 then
# line 6 "grammar.rl"
		begin

    @tokenstack.push(p)
    #puts "Mark: #{self.line(string, p)}##{self.column(string, p)}"
  		end
when 10 then
# line 84 "grammar.rl"
		begin

    name = @stack.pop
    @config ||= Hash.new { |h,k| h[k] = [] }
    @config[name] += @components
    #puts "Config component: #{name}"
  		end
when 11 then
# line 147 "grammar.rl"
		begin
 puts "END" 		end
when 12 then
# line 148 "grammar.rl"
		begin
 
            # Compute line and column of the cursor (p)
            $stderr.puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
            # TODO(sissel): Note what we were expecting?
          		end
# line 563 "grammar.rb"
		end # eof action switch
	end
	if _trigger_goto
		next
	end
end
	end
	if _goto_level <= _out
		break
	end
	end
	end

# line 186 "grammar.rl"
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
