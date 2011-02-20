
# line 1 "grammar.rl"
require "rubygems"
require "logstash/namespace"


# line 136 "grammar.rl"


class LogStash::Config::Grammar
  attr_accessor :eof
  attr_accessor :config

  def initialize
    # BEGIN RAGEL DATA
    
# line 18 "grammar.rb"
class << self
	attr_accessor :_logstash_config_actions
	private :_logstash_config_actions, :_logstash_config_actions=
end
self._logstash_config_actions = [
	0, 1, 0, 1, 2, 1, 3, 1, 
	4, 1, 8, 1, 9, 1, 10, 1, 
	11, 2, 1, 7, 2, 2, 7, 2, 
	2, 9, 2, 3, 7, 2, 5, 7, 
	2, 6, 0, 2, 8, 0, 2, 10, 
	0, 3, 1, 7, 0, 3, 2, 7, 
	0, 3, 3, 7, 0, 3, 5, 7, 
	0
]

class << self
	attr_accessor :_logstash_config_key_offsets
	private :_logstash_config_key_offsets, :_logstash_config_key_offsets=
end
self._logstash_config_key_offsets = [
	0, 0, 9, 10, 22, 27, 28, 38, 
	39, 51, 56, 57, 69, 72, 77, 82, 
	83, 84, 100, 103, 115, 127, 128, 131, 
	131, 143, 153, 153, 154, 157, 157, 159, 
	173, 187, 198, 201, 207, 213, 214, 226, 
	226, 227, 230, 230, 243, 243, 244, 253
]

class << self
	attr_accessor :_logstash_config_trans_keys
	private :_logstash_config_trans_keys, :_logstash_config_trans_keys=
end
self._logstash_config_trans_keys = [
	32, 35, 95, 9, 10, 65, 90, 97, 
	122, 10, 32, 35, 95, 123, 9, 10, 
	48, 57, 65, 90, 97, 122, 32, 35, 
	123, 9, 10, 10, 32, 35, 95, 125, 
	9, 10, 65, 90, 97, 122, 10, 32, 
	35, 95, 123, 9, 10, 48, 57, 65, 
	90, 97, 122, 32, 35, 123, 9, 10, 
	10, 32, 34, 35, 39, 95, 125, 9, 
	10, 65, 90, 97, 122, 10, 34, 92, 
	32, 35, 61, 9, 10, 32, 35, 61, 
	9, 10, 10, 62, 32, 34, 35, 39, 
	43, 45, 91, 95, 9, 10, 48, 57, 
	65, 90, 97, 122, 10, 34, 92, 32, 
	34, 35, 39, 95, 125, 9, 10, 65, 
	90, 97, 122, 32, 34, 35, 39, 95, 
	125, 9, 10, 65, 90, 97, 122, 10, 
	10, 39, 92, 32, 35, 61, 95, 9, 
	10, 48, 57, 65, 90, 97, 122, 32, 
	35, 95, 125, 9, 10, 65, 90, 97, 
	122, 10, 10, 39, 92, 48, 57, 32, 
	34, 35, 39, 95, 125, 9, 10, 48, 
	57, 65, 90, 97, 122, 32, 34, 35, 
	39, 95, 125, 9, 10, 48, 57, 65, 
	90, 97, 122, 32, 34, 35, 39, 95, 
	9, 10, 65, 90, 97, 122, 10, 34, 
	92, 32, 35, 44, 93, 9, 10, 32, 
	35, 44, 93, 9, 10, 10, 32, 34, 
	35, 39, 95, 125, 9, 10, 65, 90, 
	97, 122, 10, 10, 39, 92, 32, 35, 
	44, 93, 95, 9, 10, 48, 57, 65, 
	90, 97, 122, 10, 32, 35, 95, 9, 
	10, 65, 90, 97, 122, 32, 35, 95, 
	9, 10, 65, 90, 97, 122, 0
]

class << self
	attr_accessor :_logstash_config_single_lengths
	private :_logstash_config_single_lengths, :_logstash_config_single_lengths=
end
self._logstash_config_single_lengths = [
	0, 3, 1, 4, 3, 1, 4, 1, 
	4, 3, 1, 6, 3, 3, 3, 1, 
	1, 8, 3, 6, 6, 1, 3, 0, 
	4, 4, 0, 1, 3, 0, 0, 6, 
	6, 5, 3, 4, 4, 1, 6, 0, 
	1, 3, 0, 5, 0, 1, 3, 3
]

class << self
	attr_accessor :_logstash_config_range_lengths
	private :_logstash_config_range_lengths, :_logstash_config_range_lengths=
end
self._logstash_config_range_lengths = [
	0, 3, 0, 4, 1, 0, 3, 0, 
	4, 1, 0, 3, 0, 1, 1, 0, 
	0, 4, 0, 3, 3, 0, 0, 0, 
	4, 3, 0, 0, 0, 0, 1, 4, 
	4, 3, 0, 1, 1, 0, 3, 0, 
	0, 0, 0, 4, 0, 0, 3, 3
]

class << self
	attr_accessor :_logstash_config_index_offsets
	private :_logstash_config_index_offsets, :_logstash_config_index_offsets=
end
self._logstash_config_index_offsets = [
	0, 0, 7, 9, 18, 23, 25, 33, 
	35, 44, 49, 51, 61, 65, 70, 75, 
	77, 79, 92, 96, 106, 116, 118, 122, 
	123, 132, 140, 141, 143, 147, 148, 150, 
	161, 172, 181, 185, 191, 197, 199, 209, 
	210, 212, 216, 217, 227, 228, 230, 237
]

class << self
	attr_accessor :_logstash_config_indicies
	private :_logstash_config_indicies, :_logstash_config_indicies=
end
self._logstash_config_indicies = [
	1, 2, 3, 1, 3, 3, 0, 1, 
	2, 4, 5, 6, 7, 4, 6, 6, 
	6, 0, 8, 9, 10, 8, 0, 8, 
	9, 11, 12, 13, 14, 11, 13, 13, 
	0, 11, 12, 15, 16, 17, 18, 15, 
	17, 17, 17, 0, 19, 20, 21, 19, 
	0, 19, 20, 21, 22, 23, 24, 25, 
	26, 21, 25, 25, 0, 0, 28, 29, 
	27, 30, 31, 32, 30, 0, 33, 34, 
	35, 33, 0, 33, 34, 36, 0, 36, 
	37, 38, 39, 40, 40, 43, 42, 36, 
	41, 42, 42, 0, 0, 45, 46, 44, 
	47, 48, 49, 50, 51, 52, 47, 51, 
	51, 0, 53, 54, 55, 56, 57, 26, 
	53, 57, 57, 0, 53, 55, 0, 28, 
	59, 58, 58, 60, 61, 63, 62, 60, 
	62, 62, 62, 0, 64, 65, 66, 67, 
	64, 66, 66, 0, 44, 36, 38, 0, 
	45, 69, 68, 68, 70, 0, 71, 72, 
	73, 74, 75, 76, 71, 70, 75, 75, 
	0, 77, 78, 79, 80, 81, 82, 77, 
	81, 81, 81, 0, 83, 84, 85, 86, 
	87, 83, 87, 87, 0, 0, 89, 90, 
	88, 91, 92, 93, 94, 91, 0, 95, 
	96, 83, 97, 95, 0, 95, 96, 98, 
	99, 100, 101, 102, 103, 98, 102, 102, 
	0, 88, 83, 85, 0, 89, 105, 104, 
	104, 106, 107, 108, 110, 109, 106, 109, 
	109, 109, 0, 27, 21, 23, 1, 2, 
	3, 1, 3, 3, 0, 111, 112, 113, 
	111, 113, 113, 0, 0
]

class << self
	attr_accessor :_logstash_config_trans_targs
	private :_logstash_config_trans_targs, :_logstash_config_trans_targs=
end
self._logstash_config_trans_targs = [
	0, 1, 2, 3, 4, 5, 3, 6, 
	4, 5, 6, 6, 7, 8, 47, 9, 
	10, 8, 11, 9, 10, 11, 12, 45, 
	22, 24, 25, 12, 13, 44, 14, 15, 
	16, 14, 15, 16, 17, 18, 27, 28, 
	30, 31, 32, 33, 18, 19, 26, 20, 
	12, 21, 22, 24, 25, 20, 12, 21, 
	22, 24, 22, 23, 14, 15, 24, 16, 
	6, 7, 8, 47, 28, 29, 31, 20, 
	12, 21, 22, 24, 25, 20, 12, 21, 
	22, 32, 25, 33, 34, 40, 41, 43, 
	34, 35, 39, 36, 37, 33, 38, 36, 
	37, 38, 20, 12, 21, 22, 24, 25, 
	41, 42, 36, 37, 33, 43, 38, 1, 
	2, 3
]

class << self
	attr_accessor :_logstash_config_trans_actions
	private :_logstash_config_trans_actions, :_logstash_config_trans_actions=
end
self._logstash_config_trans_actions = [
	15, 0, 0, 1, 3, 3, 0, 23, 
	0, 0, 11, 0, 0, 1, 0, 3, 
	3, 0, 3, 0, 0, 0, 32, 0, 
	32, 32, 0, 0, 0, 0, 5, 5, 
	5, 0, 0, 0, 0, 1, 0, 1, 
	1, 1, 1, 7, 0, 0, 0, 26, 
	49, 26, 49, 49, 26, 0, 1, 0, 
	1, 1, 0, 0, 3, 3, 0, 3, 
	9, 9, 35, 9, 0, 0, 0, 17, 
	41, 17, 41, 41, 17, 20, 45, 20, 
	45, 0, 20, 0, 1, 0, 1, 1, 
	0, 0, 0, 5, 5, 5, 5, 0, 
	0, 0, 29, 53, 29, 53, 53, 29, 
	0, 0, 3, 3, 3, 0, 3, 13, 
	13, 38
]

class << self
	attr_accessor :_logstash_config_eof_actions
	private :_logstash_config_eof_actions, :_logstash_config_eof_actions=
end
self._logstash_config_eof_actions = [
	0, 15, 15, 15, 15, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 15, 15, 
	15, 15, 15, 15, 15, 15, 0, 13
]

class << self
	attr_accessor :logstash_config_start
end
self.logstash_config_start = 46;
class << self
	attr_accessor :logstash_config_first_final
end
self.logstash_config_first_final = 46;
class << self
	attr_accessor :logstash_config_error
end
self.logstash_config_error = 0;

class << self
	attr_accessor :logstash_config_en_main
end
self.logstash_config_en_main = 46;


# line 145 "grammar.rl"
    # END RAGEL DATA

    @tokenstack = Array.new
    @stack = Array.new

    @types = Hash.new { |h,k| h[k] = [] }
    @edges = []
  end

  def parse(string)
    data = string.unpack("c*")

    # BEGIN RAGEL INIT
    
# line 255 "grammar.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = logstash_config_start
end

# line 159 "grammar.rl"
    # END RAGEL INIT

    begin 
      # BEGIN RAGEL EXEC 
      
# line 268 "grammar.rb"
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

	        if data[p] < _logstash_config_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p] > _logstash_config_trans_keys[_mid]
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
	        if data[p] < _logstash_config_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p] > _logstash_config_trans_keys[_mid+1]
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
	_trans = _logstash_config_indicies[_trans]
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
# line 7 "grammar.rl"
		begin

    @tokenstack.push(p)
    #puts "Mark: #{self.line(string, p)}##{self.column(string, p)}"
  		end
when 1 then
# line 12 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "numeric: #{token}"
    #puts "numeric?: #{string[startpos,50]}"
    #puts [startpos, endpos].join(",")
    @stack << token.to_i
  		end
when 2 then
# line 22 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos ... endpos]
    #puts "string: #{token}"
    @stack << token
  		end
when 3 then
# line 30 "grammar.rl"
		begin

    startpos = @tokenstack.pop
    endpos = p
    token = string[startpos + 1 ... endpos - 1] # Skip quotations

    # Parse escapes.
    token.gsub(/\\./) { |m| return m[1,1] }
    #puts "quotedstring: #{token}"
    @stack << token
  		end
when 4 then
# line 41 "grammar.rl"
		begin

    @array = []
    @stack << :array_init
  		end
when 5 then
# line 46 "grammar.rl"
		begin

    while @stack.last != :array_init
      @array.unshift @stack.pop
    end
    @stack.pop # pop :array_init

    @stack << @array
  		end
when 6 then
# line 55 "grammar.rl"
		begin

    @parameters = Hash.new { |h,k| h[k] = [] }
  		end
when 7 then
# line 59 "grammar.rl"
		begin

    value = @stack.pop
    name = @stack.pop
    #puts "parameter: #{name} => #{value}"
    @parameters[name] << value
  		end
when 8 then
# line 66 "grammar.rl"
		begin

    @components ||= []
    name = @stack.pop
    #@components << { :name => name, :parameters => @parameters }
    @components << { name => @parameters }
  		end
when 9 then
# line 73 "grammar.rl"
		begin

    #puts "current component: " + @stack.last
    @components = []
  		end
when 10 then
# line 78 "grammar.rl"
		begin

    name = @stack.pop
    @config ||= Hash.new { |h,k| h[k] = [] }
    @config[name] += @components
  		end
when 11 then
# line 131 "grammar.rl"
		begin
 
            # Compute line and column of the cursor (p)
            puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
            # TODO(sissel): Note what we were expecting?
          		end
# line 456 "grammar.rb"
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
when 10 then
# line 78 "grammar.rl"
		begin

    name = @stack.pop
    @config ||= Hash.new { |h,k| h[k] = [] }
    @config[name] += @components
  		end
when 11 then
# line 131 "grammar.rl"
		begin
 
            # Compute line and column of the cursor (p)
            puts "Error at line #{self.line(string, p)}, column #{self.column(string, p)}: #{string[p .. -1].inspect}"
            # TODO(sissel): Note what we were expecting?
          		end
# line 500 "grammar.rb"
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

# line 164 "grammar.rl"
      # END RAGEL EXEC
    rescue => e
      # Compute line and column of the cursor (p)
      raise e
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
