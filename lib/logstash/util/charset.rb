require "logstash/namespace"
require "logstash/util"

class LogStash::Util::Charset
  attr_accessor :logger
  def initialize(charset)
    @charset = charset
  end

  def convert(data)
    data.force_encoding(@charset)
    if @charset == "UTF-8"
      # Some users don't know the charset of their logs or just don't know they
      # can set the charset setting.
      if !data.valid_encoding?
        @logger.warn("Received an event that has a different character encoding than you configured.", :text => data.inspect[1..-2], :expected_charset => @charset)
        #if @force_lossy_charset_conversion
          ## Janky hack to force ruby to re-encode UTF-8 with replacement chars.
          #data.force_encoding("CP65001")
          #data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
        #else
        #end

        # A silly hack to help convert some of the unknown bytes to
        # somewhat-readable escape codes. The [1..-2] is to trim the quotes
        # ruby puts on the value.
        data = data.inspect[1..-2]
      else
        # The user has declared the character encoding of this data is
        # something other than UTF-8. Let's convert it (as cleanly as possible)
        # into UTF-8 so we can use it with JSON, etc.
        data = data.encode("UTF-8", :invalid => :replace, :undef => :replace)
      end
    end
    return data
  end # def convert
end # class LogStash::Util::Charset

