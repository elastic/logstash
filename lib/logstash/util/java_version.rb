module LogStash::Util::JavaVersion
  # Print a warning if we're on a bad version of java
  def self.warn_on_bad_java_version
    if self.bad_java_version?(self.version)
      STDERR.puts("Please upgrade your java version, the current version '#{self.version}' may cause problems. We recommend a minimum version of 1.7.0_51")
    end
  end

  # Check to see if this is a recommended java version, print a warning to stdout if this is a bad version
  # Returns the current java version
  def self.version
    return nil if RUBY_ENGINE != "jruby"

    require 'java'
    java_import "java.lang.System"

    System.getProperties["java.runtime.version"]
  end

  def self.parse_java_version(version_string)
    return nil if version_string.nil?

    # Crazy java versioning rules @ http://www.oracle.com/technetwork/java/javase/versioning-naming-139433.html
    # The regex below parses this all correctly http://rubular.com/r/sInQc3Nc7f

    match = version_string.match(/\A(\d+)\.(\d+)\.(\d+)(_(\d+))?(-(.+))?\Z/)
    major, minor, patch, ufull, update, bfull, build = match.captures

    return {
      :full => version_string,
      :major => major.to_i,
      :minor => minor.to_i,
      :patch => patch.to_i,
      :update => update.to_i, # this is always coerced to an int (a nil will be zero) to make comparisons easier
      :build => build # not an integer, could be b06 for instance!,
    }
  end

  def self.bad_java_version?(version_string)
    return nil if version_string.nil?

    parsed = parse_java_version(version_string)

    if parsed[:major] >= 1 && parsed[:minor] == 7 && parsed[:patch] == 0 && parsed[:update] < 51
      return true
    elsif parsed[:major] >= 1 && parsed[:minor] < 7
      return true
    end
  end
end