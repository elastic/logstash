# Ruby 1.8.7 added String#start_with? - monkeypatch the
# String class if it isn't supported (<= ruby 1.8.6)
if !String.instance_methods.include?("start_with?")
  class String
    public
    def start_with?(str)
      return self[0 .. (str.length-1)] == str
    end
  end
end

# Ruby 1.8.7 added String#bytesize, used by the latest amqp gem to get the
# size of a string (instead of String#length). This monkeypatch enables older
# ruby to work, but may cause AMQP trouble on UTF-8 strings.
if !String.instance_methods.include?("bytesize")
  class String
    alias :bytesize :length
  end
end

require "logstash/rubyfixes/regexp_union_takes_array"
