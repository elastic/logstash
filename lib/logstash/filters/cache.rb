
#
# Copyright (C) 2002  Yoshinori K. Okuji &lt;okuji@enbug.org&gt;
#
# You may redistribute it and/or modify it under the same term as Ruby.

# Cache manager based on the LRU algorithm.
class Cache

  CACHE_OBJECT = Struct.new('CacheObject', :content, :size, :atime)
  CACHE_VERSION = '0.3'

  include Enumerable
  
  def self.version
    CACHE_VERSION
  end

  # initialize(max_obj_size = nil, max_size = nil, max_num = nil,
  #            expiration = nil, &amp;hook)
  # initialize(hash, &amp;hook)
  def initialize(*args, &amp;hook)
    if args.size == 1 and args[0].kind_of?(Hash)
      @max_obj_size = @max_size = @max_num = @expiration = nil
      args[0].each do |k, v|
	k = k.intern if k.respond_to?(:intern)
	case k
	when :max_obj_size
	  @max_obj_size = v
	when :max_size
	  @max_size = v
	when :max_num
	  @max_num = v
	when :expiration
	  @expiration = v
	end
      end
    else
      @max_obj_size, @max_size, @max_num, @expiration = args
    end

    # Sanity checks.
    if @max_obj_size and @max_size and @max_obj_size &gt; @max_size
      raise ArgumentError, "max_obj_size exceeds max_size (#{@max_obj_size} &gt; #{@max_size})"
    end
    if @max_obj_size and @max_obj_size &lt;= 0
      raise ArgumentError, "invalid max_obj_size `#{@max_obj_size}'"
    end
    if @max_size and @max_size &lt;= 0
      raise ArgumentError, "invalid max_size `#{@max_size}'"
    end
    if @max_num and @max_num &lt;= 0
      raise ArgumentError, "invalid max_num `#{@max_num}'"
    end
    if @expiration and @expiration &lt;= 0
      raise ArgumentError, "invalid expiration `#{@expiration}'"
    end
    
    @hook = hook
    
    @objs = {}
    @size = 0
    @list = []
    
    @hits = 0
    @misses = 0
  end

  attr_reader :max_obj_size, :max_size, :max_num, :expiration

  def cached?(key)
    @objs.include?(key)
  end
  alias :include? :cached?
  alias :member? :cached?
  alias :key? :cached?
  alias :has_key? :cached?

  def cached_value?(val)
    self.each_value do |v|
      return true if v == val
    end
    false
  end
  alias :has_value? :cached_value?
  alias :value? :cached_value?

  def index(val)
    self.each_pair do |k,v|
      return k if v == val
    end
    nil
  end

  def keys
    @objs.keys
  end

  def length
    @objs.length
  end
  alias :size :length

  def to_hash
    @objs.dup
  end

  def values
    @objs.collect {|key, obj| obj.content}
  end
  
  def invalidate(key)
    obj = @objs[key]
    if obj
      if @hook
	@hook.call(key, obj.content)
      end
      @size -= obj.size
      @objs.delete(key)
      @list.each_index do |i|
	if @list[i] == key
	  @list.delete_at(i)
	  break
	end
      end
    elsif block_given?
      return yield(key)
    end
    obj.content
  end
  alias :delete :invalidate

  def invalidate_all()
    if @hook
      @objs.each do |key, obj|
	@hook.call(key, obj)
      end
    end

    @objs.clear
    @list.clear
    @size = 0
  end
  alias :clear :invalidate_all
  
  def expire()
    if @expiration
      now = Time.now.to_i
      @list.each_index do |i|
	key = @list[i]
	
	break unless @objs[key].atime + @expiration &lt;= now
	self.invalidate(key)
      end
    end
#    GC.start
  end
	
  def [](key)
    self.expire()
    
    unless @objs.include?(key)
      @misses += 1
      return nil
    end
    
    obj = @objs[key]
    obj.atime = Time.now.to_i

    @list.each_index do |i|
      if @list[i] == key
	@list.delete_at(i)
	break
      end
    end
    @list.push(key)

    @hits += 1
    obj.content
  end
  
  def []=(key, obj)
    self.expire()
    
    if self.cached?(key)
      self.invalidate(key)
    end

    size = obj.to_s.size
    if @max_obj_size and @max_obj_size &lt; size
      if $DEBUG
	$stderr.puts("warning: `#{obj.inspect}' isn't cached because its size exceeds #{@max_obj_size}")
      end
      return obj
    end
    if @max_obj_size.nil? and @max_size and @max_size &lt; size
      if $DEBUG
	$stderr.puts("warning: `#{obj.inspect}' isn't cached because its size exceeds #{@max_size}")
      end
      return obj
    end
      
    if @max_num and @max_num == @list.size
      self.invalidate(@list.first)
    end

    @size += size
    if @max_size
      while @max_size &lt; @size
	self.invalidate(@list.first)
      end
    end

    @objs[key] = CACHE_OBJECT.new(obj, size, Time.now.to_i)
    @list.push(key)

    obj
  end

  def store(key, value)
    self[key] = value
  end

  def each_pair
    @objs.each do |key, obj|
      yield key, obj.content
    end
    self
  end
  alias :each :each_pair

  def each_key
    @objs.each_key do |key|
      yield key
    end
    self
  end

  def each_value
    @objs.each_value do |obj|
      yield obj.content
    end
    self
  end

  def empty?
    @objs.empty?
  end

  def fetch(key, default = nil)
    val = self[key]
    if val.nil?
      if default
	val = self[key] = default
      elsif block_given?
	val = self[key] = yield(key)
      else
	raise IndexError, "invalid key `#{key}'"
      end
    end
    val
  end
  
  # The total size of cached objects, the number of cached objects,
  # the number of cache hits, and the number of cache misses.
  def statistics()
    [@size, @list.size, @hits, @misses]
  end
end

# Run a test, if executed.
if __FILE__ == $0
  cache = Cache.new(100 * 1024, 100 * 1024 * 1024, 256, 1)
  1000.times do
    key = rand(1000)
    cache[key] = key.to_s
  end
  1000.times do
    key = rand(1000)
    puts cache[key]
  end
  sleep 1
  1000.times do
    key = rand(1000)
    puts cache[key]
  end
  
  stat = cache.statistics()
  hits = stat[2]
  misses = stat[3]
  ratio = hits.to_f / (hits + misses)
  
  puts "Total size:\t#{stat[0]}"
  puts "Number:\t\t#{stat[1]}"
  puts "Hit ratio:\t#{ratio * 100}% (#{hits} / #{hits + misses})"
end
