# encoding: utf-8
# Monkeypatch for JRUBY-6970
module Kernel
  alias_method :require_JRUBY_6970_hack, :require

  def require(path)
    old_load_path = nil

    if path =~ /^jar:file:.+!.+/
      path = path.gsub(/^jar:/, "")
      puts "JRUBY-6970: require(#{path})" if ENV["REQUIRE_DEBUG"] == "1"
    end

    # Work around slow openssl load times in flatjar. (LOGSTASH-1223)
    # I don't know why this works, I don't care either. This problem only
    # exists in the 'jar' builds of logstash which are going to be going away
    # soon in favor of the much-better tarball/zip releases!
    if __FILE__ =~ /^(?:jar:)?file:.+!.+/ && path == "openssl"
      # Loading shared/jruby-openssl first seems to make openssl load faster
      # I have no idea. Computers.
      require_JRUBY_6970_hack "shared/jruby-openssl"
      return require_JRUBY_6970_hack "openssl"
    end

    # JRUBY-7065
    path = File.expand_path(path) if path.include?("/../")
    rc = require_JRUBY_6970_hack(path)

    # Only monkeypatch openssl after it's been loaded.
    if path == "openssl"
      require "logstash/JRUBY-6970-openssl"
    end
    return rc
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
      #p :expand_path => [path, dir]
      if path =~ /(jar:)?file:\/.*\.jar!/
        #p :expand_path_path => [path, dir]
        jar, resource = path.split("!", 2)
        #p :expand_path => [jar, resource]
        if resource.nil? || resource == ""
          # Nothing after the "!", nothing special to handle.
          return expand_path_JRUBY_6970(path, dir)
        else
          resource = expand_path_JRUBY_6970(resource, dir)
          return fix_jar_path(jar, resource)
        end
      elsif dir =~ /(jar:)?file:\/.*\.jar!/
        jar, dir = dir.split("!", 2)
        if dir.empty?
          # sometimes the original dir is just 'file:/foo.jar!'
          return File.join("#{jar}!", path) 
        end
        dir = expand_path_JRUBY_6970(path, dir)
        return fix_jar_path(jar, dir)
      else
        return expand_path_JRUBY_6970(path, dir)
      end
    end
  end

  protected

  def self.fix_jar_path(jar, resource)
    # TODO(sissel): use LogStash::Util::UNAME
    if RbConfig::CONFIG["host_os"] == "mswin32"
      # 'expand_path' on "/" will return "C:/" on windows.
      # So like.. we don't want that because technically this
      # is the root of the jar, not of a disk.
      #puts :fix_jar_path => ["#{jar}!#{resource.gsub(/^[A-Za-z]:/, "")}"]
      return "#{jar}!#{resource.gsub(/^[A-Za-z]:/, "")}"
    else
      return "#{jar}!#{resource}"
    end
  end
end

class Dir
  class << self
    alias_method :glob_JRUBY_6970_hack, :glob
    def glob(path, flags=nil)
      if path =~ /^jar:file:/
        # Strip leading 'jar:' (LOGSTASH-1316)
        return glob_JRUBY_6970_hack(path.gsub(/^jar:/, ""))
      else
        return glob_JRUBY_6970_hack(path)
      end
    end
  end
end
