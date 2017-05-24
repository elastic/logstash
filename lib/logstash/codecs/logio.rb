# encoding: utf-8
require "logstash/codecs/base"

#
# Log.io Codec Plugin for Logstash (http://logstash.net)
# Author: Luke Chavers <github.com/vmadman>
# Created: 11/22/2013
# Current Logstash: 1.2.2
#
# To the extent possible under law, Luke Chavers has waived all copyright and related
# or neighboring rights to this work.  You are free to distribute, modify, and use
# this work without permission of any kind.  Attribution is appreciated, but is not required.
#
# This codec formats events for output to Log.io, a log stream viewer
# built on Node.JS (http://logio.org/). Log.io is Copyright 2011-2013 Narrative Science Inc.
# and is released under the Apache 2.0 license. (http://www.apache.org/licenses/LICENSE-2.0.html)
#
#     output {
#      tcp {
#       codec => logio {
#         debug_output => "true"
#       }
#       host => "127.0.0.1"
#       port => 28777
#      }
#     }
#
# Important Note:  This codec is only useful when applied to OUTPUTs
#
class LogStash::Codecs::LogIO < LogStash::Codecs::Base
  config_name "logio"
  milestone 1

  # Applies to ALL output.  Set the TIME output format (Ruby).  Date directives
  # are allowed but are not included in the default because log.io does not persist
  # events, making them rather pointless.
  #
  # The default will yield: '09:45:15 AM UTC'
  #
  # See: http://www.ruby-doc.org/core-2.0.0/Time.html#method-i-strftime
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #                       ^
  config :timestamp_format, :validate => :string, :default => "%I:%M:%S %p %Z"

  # Only applies to STANDARD output.  Set the message you which to emit for
  # each event. This supports sprintf strings.
  #
  #     myapp something >> 09:45:15 AM UTC : An event happened
  #                                           ^
  config :standard_message_format, :validate => :string, :default => "%{message}"

  # Only applies to STANDARD output.  This specifies the string to
  # use for the 'log level' that is passed to log.io. This supports sprintf strings.
  # This setting affects the RAW output to log.io and, as far as I can tell, it does
  # not affect what log.io displays in any way.
  #
  #     +log|myapp|something|DEBUG|A message here...
  #                            ^
  config :standard_log_level_format, :validate => :string, :default => "DEBUG"

  # Only applies to DEBUG output.  This specifies the string to
  # use for the 'stream' that is passed to log.io. This supports sprintf strings.
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #       ^
  config :standard_stream_format, :validate => :string, :default => "%{type}"

  # Only applies to DEBUG output.  This specifies the string to
  # use for the 'node' that is passed to log.io. This supports sprintf strings.
  #
  #     myapp something >> 09:45:15 AM UTC : An event happened
  #             ^
  config :standard_node_format, :validate => :string, :default => "%{source}"

  # When TRUE additional debug information will be sent that shows
  # the full contents of the event as they were when they arrived
  # at this output.  This is very handy for debugging logstash configs.
  # The example below is shortened for so that it would fit this document:
  #
  #     debug myapp >> 09:45:15 AM UTC :
  #     debug myapp >> 09:45:15 AM UTC : -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  #     debug myapp >> 09:45:15 AM UTC :
  #     debug myapp >> 09:45:15 AM UTC : ..... "message" => "app started",
  #     debug myapp >> 09:45:15 AM UTC : .. "@timestamp" => "2000-12-21T01:00:00.123Z",
  #     debug myapp >> 09:45:15 AM UTC : .... "@version" => "1",
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #
  # Note: Since Log.io allows you to filter by stream, the debug output is sent
  # along with the standard output.  (they're not mutually exclusive)
  #
  # The conversion and tranmission of events into debug format is likely relatively
  # expensive and is not advised for use in production environments.
  config :debug_output, :validate => :boolean, :default => false

  # Only applies to DEBUG output.  This specifies the string to
  # use for the 'stream' that is passed to log.io. This supports sprintf strings.
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #       ^
  config :debug_stream_format, :validate => :string, :default => "debug"

  # Only applies to DEBUG output.  This specifies the string to
  # use for the 'node' that is passed to log.io. This supports sprintf strings.
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #             ^
  config :debug_node_format, :validate => :string, :default => "%{type}"

  # Only applies to DEBUG output.  This specifies the string to
  # use for the 'log level' that is passed to log.io. This supports sprintf strings.
  # This setting affects the RAW output to log.io and, as far as I can tell, it does
  # not affect what log.io displays in any way.
  #
  #     +log|debug|myapp|DEBUG|A message here...
  #                        ^
  config :debug_log_level_format, :validate => :string, :default => "DEBUG"

  # Only applies to DEBUG output.  To help ensure that all '=>' arrows line
  # up in debug output, even across multiple events, we'll use this number
  # to enforce a rough min length for the padding and hash key of each field.
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #                                      ^             ^ = 14
  config :debug_eq_left_length, :validate => :number, :default => 35

  # Only applies to DEBUG output.  To help ensure that all event timestamps
  # line up in debug output, even across multiple events, we'll use this number
  # to enforce a rough min length for the stream and node fields in the output.
  #
  #     debug myapp >> 09:45:15 AM UTC : ....... "type" => "myapp",
  #     ^            ^ = 13
  config :debug_stream_node_length, :validate => :number, :default => 20

  # The constructor (of sorts)
  public
  def register

    # We need this for awesome_inspect
    require "ap"

  end


  # Decode: Convert incoming
  # This is not supported by this codec as it would not serve a purpose.
  public
  def decode(data)
    raise "The Log.io Codec cannot be used to decode messages (i.e. on an input)."
  end

  public

  # Encode: Encode the data for transport
  def encode(data)

    # Find date/time string
    field_time    = data['@timestamp'].strftime(@timestamp_format)

    # Handle the debug transmission, if desired
    if @debug_output == true

      # This code IS a bit sloppy.  This is due to my lack of
      # Ruby knowledge/skill.  Since this won't be used in production (hopefully),
      # it should not matter very much.

      # Resolve a few strings
      debug_field_stream  = data.sprintf(@debug_stream_format)
      debug_field_node    = data.sprintf(@debug_node_format)
      debug_field_level   = data.sprintf(@debug_log_level_format)

      # Create the event divider line:
      #
      #     debug myapp >> 09:45:15 AM UTC :
      #     debug myapp >> 09:45:15 AM UTC : -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
      #     debug myapp >> 09:45:15 AM UTC :
      #
      div = "\n" + ("-=" * 100) + "-\n"

      # Create the initial string
      str = div + "\n" + data.to_hash.awesome_inspect

      # Log.io will eliminate extra whitespace so
      # we have to use dots to indent.
      #
      #     debug myapp >> 09:45:15 AM UTC : ..... "message" => "app started",
      #                                        ^
      str = str.gsub(/  /,'..')
      
      # This code ensures there is a space after the dots but before
      # the hash key of the event.
      #
      #     debug myapp >> 09:45:15 AM UTC : ..... "message" => "app started",
      #                                           ^
      str = str.gsub(/\.\.\."/,'.. "')

      # These dots will be added to array elements because 
      # .awesome_inspect does not properly indent arrays.
      #
      #     debug myapp >> 09:45:15 AM UTC : .... "tags" => [
      #     debug myapp >> 09:45:15 AM UTC : .................. [0] "example",
      #                                                  ^      
      array_element_indent = "......................."

      # Ensures that there is a space between the dots and [ start of array elements
      #
      #     debug myapp >> 09:45:15 AM UTC : .................. [0] "example",
      #                                                        ^      
      str = str.gsub(/\.\.\.\[/,array_element_indent + '.. [')
      
      # Ensures that there is a space between the dots and ] end of arrays
      #
      #     debug myapp >> 09:45:15 AM UTC : ............... ]
      #                                                     ^      
      str = str.gsub(/\.\.\.\]/,array_element_indent + '.. ]')

      # Split our multi-line string into an array
      arr = str.split(/\n/)
      
      # --------------------------------------------------------------------
      # Note:
      #   awesome_inspect() right aligns keys to make => assignments line up.
      #   However, since it calculates the alignment point based on the lengths
      #   of the keys in the current event (only) we will enforce a minimum
      #   indentention so that ALL events line up properly by padding messages
      #   to a minimum dot indention.
      # --------------------------------------------------------------------

      # We'll base the padding on the index (location) of the '=' equal sign
      # in the 4th line of our array.  The fourth line is actually the first
      # hash key (usually 'message') because of our div and blank lines that surround it.      
      pad_length_check_index = 4
      equal_sign_index = arr[pad_length_check_index].index('=')

      # This shouldn't happen, but just in case there is not an '=' sign
      # in our checked string we'll report an error.
      if equal_sign_index.nil?
      
        ident_consistency_padding = ""
        @on_event.call("+log|debug|logio_codec|WARNING|Parse Error 001: The message did not contain an equal sign where expected.\r\n")
              
      else
      
        # We force the hash key length + padding to
        # be at least @debug_eq_left_length characters/bytes.
        consistency_padding_amount = @debug_eq_left_length - equal_sign_index

        # Just in case it's too long.  This will result in weird
        # output but shouldn't break anything.
        if( consistency_padding_amount > 0 )
          ident_consistency_padding = "." * consistency_padding_amount
        else
          ident_consistency_padding = ""
          @on_event.call("+log|debug|logio_codec|WARNING|Parse Error 002: Long field name found, consider increasing codec param: debug_eq_left_length\r\n")
        end
              
      end

      # Because log.io prepends messages with the node and stream names,
      # we will padd our messages using '>' to make them line up in the buffer.
      # The 'stream' is actually fixed, so we only have to pad based on the 'node'.
      stream_concat = debug_field_stream + " " + debug_field_node
      stream_length = stream_concat.length
      if( stream_length < @debug_stream_node_length )
        neg_stream_length = @debug_stream_node_length - stream_length
      else
        neg_stream_length = 0
        @on_event.call("+log|debug|logio_codec|WARNING|Parse Error 003: Long node and stream found, consider increasing codec param: debug_stream_node_length\r\n")
      end
      stream_padding = ">" * neg_stream_length

      # Output each line of our array
      arr.each_with_index do |line,index|

        if( index < 4 )
          real_field_indent_string = ''
        else
          real_field_indent_string = ident_consistency_padding
        end

        # We will not show the { and } lines as they just waste space
        if (line != "{" && line != "}")

          # Output!
          @on_event.call("+log|" + debug_field_stream + "|" + debug_field_node + "|" + debug_field_level + "|" + stream_padding + " " + field_time + " : " + real_field_indent_string + line + "\r\n")

        end

      end

    end

    # Perform standard output
    # e.g. +log|debug|myapp|INFO|A log message\r\n
    
    # Resolve a few strings
    standard_field_stream   = data.sprintf(@standard_stream_format)
    standard_field_node     = data.sprintf(@standard_node_format)
    standard_field_level    = data.sprintf(@standard_log_level_format)

    if data.is_a? LogStash::Event and @standard_message_format
      standard_field_message  = data.sprintf(@standard_message_format)
      @on_event.call("+log|" + standard_field_stream + "|" + standard_field_node + "|" + standard_field_level + "|" + field_time + " : " + standard_field_message + "\r\n")
    else
      @on_event.call("+log|" + standard_field_stream + "|" + standard_field_node + "|" + standard_field_level + "|" + field_time + " : Raw Output (parse failure): " + data.to_s + "\r\n")
      @on_event.call("+log|standard|logio_codec|WARNING|Parse Error 004: Unable to process event or missing standard_message_format.\r\n")
    end

  end

end