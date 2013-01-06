# Monkeypatch for JRUBY-6970
module Kernel
  alias_method :require_JRUBY_6970_hack, :require

  def require(path)
    if path =~ /^jar:file:.+!.+/
      path = path.gsub(/^jar:/, "")
      puts "JRUBY-6970: require(#{path})" if ENV["REQUIRE_DEBUG"] == "1"
    end
    return require_JRUBY_6970_hack(path)
  end
end

require "openssl"
class OpenSSL::SSL::SSLContext
  alias_method :ca_path_JRUBY_6970=, :ca_path=
  alias_method :ca_file_JRUBY_6970=, :ca_file=

  def ca_file=(arg)
    if arg =~ /^jar:file:\//
      return ca_file_JRUBY_6970=(arg.gsub(/^jar:/, ""))
    end
    return ca_file_JRUBY_6970=(arg)
  end

  def ca_path=(arg)
    if arg =~ /^jar:file:\//
      return ca_path_JRUBY_6970=(arg.gsub(/^jar:/, ""))
    end
    return ca_path_JRUBY_6970=(arg)
  end
end

# Work around for a bug in File.expand_path that doesn't account for resources
# in jar paths.
#
# Should solve this error:
#   Exception in thread "LogStash::Runner" org.jruby.exceptions.RaiseException:
#   (Errno::ENOENT) file:/home/jls/projects/logstash/build/data/unicode.data
class File
  class << self
    alias_method :expand_path_JRUBY_6970, :expand_path

    def expand_path(path, dir=nil)
      if path =~ /(jar:)?file:\/.*\.jar!/
        jar, resource = path.split("!", 2)
        return "#{jar}!#{expand_path_JRUBY_6970(resource, dir)}"
      else
        return expand_path_JRUBY_6970(path, dir)
      end
    end
  end
end

