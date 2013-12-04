# encoding: utf-8
# TODO(sissel): require "openssl" takes *ages* from the logstash jar
# TODO(sissel): monkeypatch Kernel.require to apply this monkeypatch only after
# a 'require "openssl" has occurred.
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
