# This patch fixes a problem that exists in JRuby prior to 1.7.11 where the
# ruby binary path used by rubygems is malformed on Windows, causing
# dependencies to not install cleanly when using `.\bin\logstash.bat deps`.
# This monkeypatch can probably be removed once it's unlikely that people
# are still using JRuby older than 1.7.11.
  class << Gem
    def ruby
      ruby_path = original_ruby
      ruby_path = "java -jar #{jar_path(ruby_path)}" if jarred_path?(ruby_path)
      ruby_path
    end

    def jarred_path?(p)
      p =~ /^file:/
    end

    # A jar path looks like this on non-Windows platforms:
    #   file:/path/to/file.jar!/path/within/jar/to/file.txt
    # and like this on Windows:
    #   file:/C:/path/to/file.jar!/path/within/jar/to/file.txt
    #
    # This method returns:
    #   /path/to/file.jar
    # or
    #   C:/path/to/file.jar
    # as appropriate.
    def jar_path(p)
      path = p.sub(/^file:/, "").sub(/!.*/, "")
      path = path.sub(/^\//, "") if win_platform? && path =~ /^\/[A-Za-z]:/
      path
    end
  end
