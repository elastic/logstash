# encoding: utf-8
require "logstash/namespace"
require "logstash/environment"

module LogStash::Util
  UNAME = case RbConfig::CONFIG["host_os"]
    when /^linux/; "linux"
    else; RbConfig::CONFIG["host_os"]
  end

  PR_SET_NAME = 15
  def self.set_thread_name(name)
    if RUBY_ENGINE == "jruby"
      # Keep java and ruby thread names in sync.
      Java::java.lang.Thread.currentThread.setName(name)
    end
    Thread.current[:name] = name

    if UNAME == "linux"
      require "logstash/util/prctl"
      # prctl PR_SET_NAME allows up to 16 bytes for a process name
      # since MRI 1.9, JRuby, and Rubinius use system threads for this.
      LibC.prctl(PR_SET_NAME, name[0..16], 0, 0, 0)
    end
  end # def set_thread_name

  # Merge hash 'src' into 'dst' nondestructively
  #
  # Duplicate keys will become array values
  #
  # [ src["foo"], dst["foo"] ]
  def self.hash_merge(dst, src)
    src.each do |name, svalue|
      if dst.include?(name)
        dvalue = dst[name]
        if dvalue.is_a?(Hash) && svalue.is_a?(Hash)
          dvalue = hash_merge(dvalue, svalue)
        elsif svalue.is_a?(Array)
          if dvalue.is_a?(Array)
            # merge arrays without duplicates.
            dvalue |= svalue
          else
            dvalue = [dvalue] | svalue
          end
        else
          if dvalue.is_a?(Array)
            dvalue << svalue unless dvalue.include?(svalue)
          else
            dvalue = [dvalue, svalue] unless dvalue == svalue
          end
        end

        dst[name] = dvalue
      else
        # dst doesn't have this key, just set it.
        dst[name] = svalue
      end
    end

    return dst
  end # def self.hash_merge

  # Merge hash 'src' into 'dst' nondestructively
  #
  # Duplicate keys will become array values
  # Arrays merged will simply be appended.
  #
  # [ src["foo"], dst["foo"] ]
  def self.hash_merge_with_dups(dst, src)
    src.each do |name, svalue|
      if dst.include?(name)
        dvalue = dst[name]
        if dvalue.is_a?(Hash) && svalue.is_a?(Hash)
          dvalue = hash_merge(dvalue, svalue)
        elsif svalue.is_a?(Array)
          if dvalue.is_a?(Array)
            # merge arrays without duplicates.
            dvalue += svalue
          else
            dvalue = [dvalue] + svalue
          end
        else
          if dvalue.is_a?(Array)
            dvalue << svalue unless dvalue.include?(svalue)
          else
            dvalue = [dvalue, svalue] unless dvalue == svalue
          end
        end

        dst[name] = dvalue
      else
        # dst doesn't have this key, just set it.
        dst[name] = svalue
      end
    end

    return dst
  end # def self.hash_merge

  def self.hash_merge_many(*hashes)
    dst = {}
    hashes.each do |hash|
      hash_merge_with_dups(dst, hash)
    end
    return dst
  end # def hash_merge_many


  # nomalize method definition based on platform.
  # normalize is used to convert an object create through
  # json deserialization from JrJackson in :raw mode to pure Ruby
  # to support these pure Ruby object monkey patches.
  # see logstash/json.rb and logstash/java_integration.rb

  if LogStash::Environment.jruby?
    require "java"

    # recursively convert any Java LinkedHashMap and ArrayList to pure Ruby.
    # will not recurse into pure Ruby objects. Pure Ruby object should never
    # contain LinkedHashMap and ArrayList since these are only created at
    # initial deserialization, anything after (deeper) will be pure Ruby.
    def self.normalize(o)
      case o
      when Java::JavaUtil::LinkedHashMap
        o.inject({}){|r, (k, v)| r[k] = normalize(v); r}
      when Java::JavaUtil::ArrayList
        o.map{|i| normalize(i)}
      else
        o
      end
    end

  else

    # identity function, pure Ruby object don't need normalization.
    def self.normalize(o); o; end
  end


end # module LogStash::Util
