# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/environment"

module LogStash::Util
  UNAME = case RbConfig::CONFIG["host_os"]
    when /^linux/; "linux"
    else; RbConfig::CONFIG["host_os"]
  end

  PR_SET_NAME = 15

  def self.set_thread_name(name)
    previous_name = Java::java.lang.Thread.currentThread.getName() if block_given?

    # Keep java and ruby thread names in sync.
    Java::java.lang.Thread.currentThread.setName(name)
    Thread.current[:name] = name

    if UNAME == "linux"
      require "logstash/util/prctl"
      # prctl PR_SET_NAME allows up to 16 bytes for a process name
      LibC.prctl(PR_SET_NAME, name[0..16], 0, 0, 0)
    end

    if block_given?
      begin
        yield
      ensure
        set_thread_name(previous_name)
      end
    end
  end # def set_thread_name

  def self.set_thread_plugin(plugin)
    Thread.current[:plugin] = plugin
  end

  def self.with_logging_thread_context(override_context)
    java_import org.apache.logging.log4j.ThreadContext

    backup = ThreadContext.getImmutableContext()
    ThreadContext.putAll(override_context)

    yield

  ensure
    ThreadContext.removeAll(override_context.keys)
    ThreadContext.putAll(backup)
  end

  def self.thread_info(thread)
    # When the `thread` is dead, `Thread#backtrace` returns `nil`; fall back to an empty array.
    backtrace = (thread.backtrace || []).map do |line|
      line.sub(LogStash::Environment::LOGSTASH_HOME, "[...]")
    end

    blocked_on = case backtrace.first
                 when /in `push'/ then "blocked_on_push"
                 when /(?:pipeline|base).*pop/ then "waiting_for_events"
                 else nil
                 end

    {
      "thread_id" => get_thread_id(thread), # might be nil for dead threads
      "name" => thread[:name] || get_thread_name(thread),
      "plugin" => (thread[:plugin] ? thread[:plugin].debug_info : nil),
      "backtrace" => backtrace,
      "blocked_on" => blocked_on,
      "status" => thread.status,
      "current_call" => backtrace.first
    }
  end

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

  # normalize method definition based on platform.
  # normalize is used to convert an object create through
  # json deserialization from JrJackson in :raw mode to pure Ruby
  # to support these pure Ruby object monkey patches.
  # see logstash/json.rb and logstash/java_integration.rb

  require "java"
  # recursively convert any Java LinkedHashMap and ArrayList to pure Ruby.
  # will not recurse into pure Ruby objects. Pure Ruby object should never
  # contain LinkedHashMap and ArrayList since these are only created at
  # initial deserialization, anything after (deeper) will be pure Ruby.
  def self.normalize(o)
    case o
    when Java::JavaUtil::LinkedHashMap
      o.inject({}) {|r, (k, v)| r[k] = normalize(v); r}
    when Java::JavaUtil::ArrayList
      o.map {|i| normalize(i)}
    else
      o
    end
  end

  def self.stringify_symbols(o)
    case o
    when Hash
      o.inject({}) {|r, (k, v)| r[k.is_a?(Symbol) ? k.to_s : k] = stringify_symbols(v); r}
    when Array
      o.map {|i| stringify_symbols(i)}
    when Symbol
      o.to_s
    else
      o
    end
  end

  # Take a instance reference and return the name of the class
  # stripping all the modules.
  #
  # @param [Object] The object to return the class)
  # @return [String] The name of the class
  def self.class_name(instance)
    instance.class.name.split("::").last
  end

  def self.deep_clone(o)
    case o
    when Hash
      o.inject({}) {|h, (k, v)| h[k] = deep_clone(v); h }
    when Array
      o.map {|v| deep_clone(v) }
    when Integer, Symbol, IO, TrueClass, FalseClass, NilClass
      o
    when LogStash::Codecs::Base
      o.clone
    when String
      o.clone #need to keep internal state e.g. frozen
    when LogStash::Timestamp
      o.clone
    else
      Marshal.load(Marshal.dump(o))
    end
  end

  # Returns true if the object is considered blank.
  # A blank includes things like '', '   ', nil,
  # and arrays and hashes that have nothing in them.
  #
  # This logic is mostly shared with ActiveSupport's blank?
  def self.blank?(value)
    if value.kind_of?(NilClass)
      true
    elsif value.kind_of?(String)
      value !~ /\S/
    else
      value.respond_to?(:empty?) ? value.empty? : !value
    end
  end
end # module LogStash::Util
