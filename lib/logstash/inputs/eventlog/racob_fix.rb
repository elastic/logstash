# encoding: utf-8
# The jruby-win32ole gem uses 'java.lang.System.set_property' to
# tell java(?) where to find the racob dll.
#
# However, it fails when it tries to load the racob dll from the jar
# (UnsatisfiedLinkError).
#
# So easy fix, right? Monkeypatch the set_property to do two things:
#   - extract the racob dll somewhere
#   - set the property to the extracted path
#

require "fileutils"
require "tmpdir"

class << java.lang.System
  alias_method :set_property_seriously, :set_property
  def set_property(key, value)
    if key == "racob.dll.path" && value =~ /file:.*\.jar!\//
      # Path is set in a jar, we'll need to extract it to a
      # temporary location, then load it.
      filename = File.basename(value)
      extracted_path = File.join(Dir.tmpdir, filename)
      # FileUtils.cp (and copy, and copy_file) are broken
      # when copying this file. I have not debugged it other
      # than to see it doesn't work. racob_x86.dll is 105kb,
      # but FileUtils.cp only copies 4kb of it.
      
      # open both files in 'binary' mode (sets encoding to BINARY aka
      # ASCII-8BIT).
      input = File.new(value, "rb") 
      output = File.new(extracted_path, "wb")
      while chunk = input.read(16384)
        output.write(chunk) 
      end
      input.close
      output.close

      return set_property_seriously(key, extracted_path)
    else
      return set_property_seriously(key, value)
    end
  end
end
