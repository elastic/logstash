# encoding: utf-8
require 'cabin'

module LogStash::Util::JavaVersion
  def self.logger
    @logger ||= Cabin::Channel.get(LogStash)
  end

  # Print a warning if we're on a bad version of java
  def self.warn_on_bad_java_version
    if self.bad_java_version?(self.version)
      msg = "!!! Please upgrade your java version, the current version '#{self.version}' may cause problems. We recommend a minimum version of 1.7.0_51"
      STDERR.puts(msg)
      logger.warn(msg)
    end
  end

  # Return the current java version string. Returns nil if this is a non-java platform (e.g. MRI).
  def self.version
    return nil unless LogStash::Environment.jruby?
    java.lang.System.getProperty("java.runtime.version")
  end

  # Takes a string of a java version ex: "1.8.0_24-beta"
  # and returns a parsed map of the components.
  # nil inputs will be returned as nil.
  def self.parse_java_version(version_string)
    return nil if version_string.nil?

    # Crazy java versioning rules @ http://www.oracle.com/technetwork/java/javase/versioning-naming-139433.html
    # The regex below parses this all correctly http://rubular.com/r/sInQc3Nc7f

    match = version_string.match(/\A(\d+)\.(\d+)\.(\d+)(_(\d+))?(-(.+))?\Z/)

    return nil unless match

    major, minor, patch, ufull, update, bfull, build = match.captures

    {
      :full => version_string,
      :major => major.to_i,
      :minor => minor.to_i,
      :patch => patch.to_i,
      :update => update.to_i, # this is always coerced to an int (a nil will be zero) to make comparisons easier
      :build => build # not an integer, could be b06 for instance!,
    }
  end

  # Determine if the given java version string is a bad version of java
  # If it is, return true, if it isn't return false.
  # Accepts nil, returning nil.
  def self.bad_java_version?(version_string)
    return nil if version_string.nil?

    parsed = parse_java_version(version_string)
    return false unless parsed

    if parsed[:major] == 1 && parsed[:minor] == 7 && parsed[:patch] == 0 && parsed[:update] < 51
      true
    elsif parsed[:major] == 1 && parsed[:minor] < 7
      true
    else
      false
    end
  end
end
