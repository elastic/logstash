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
