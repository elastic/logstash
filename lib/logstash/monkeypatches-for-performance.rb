# encoding: utf-8
if RUBY_PLATFORM == "java"
  class << File
    # mpp == monkey patch for performance
    alias_method :mpp_file?, :file?
    alias_method :mpp_exist?, :exist?
    alias_method :mpp_exists?, :exists?

    JAR_RE = /^(?:jar:)?file:(\/.*\.jar)!(\/.*$)/
    def file?(path)
      #return mpp_file?(path)
      # If path is in a jar (file://blah/foo.jar!/some/path)
      #   - create a cache for this jar of all files
      #   - return cached results only
      if RUBY_PLATFORM == "java" 
        m = JAR_RE.match(path)
        return mpp_file?(path) if !m # not a jar file
        c = __zipcache(m[1], m[2]) # m[1] == the jar path
        # ZipEntry has only 'isDirectory()' so I assume any
        # non-directories are files.
        rc = (!c.nil? && !c.isDirectory)
        #p path => rc
        return rc
      end
      return mpp_file?(path)
    end

    def exist?(path)
      #return mpp_exist?(path)
      # If path is in a jar (file://blah/foo.jar!/some/path)
      #   - create a cache for this jar of all files
      #   - return cached results only
      if RUBY_PLATFORM == "java" 
        m = JAR_RE.match(path)
        return mpp_exists?(path) if !m # not a jar file
        c = __zipcache(m[1], m[2]) # m[1] == the jar path
        return !c.nil?
      end
      return mpp_exists?(path)
    end

    def exists?(path)
      return exist?(path)
    end

    def __zipcache(jarpath, path)
      @jarcache ||= Hash.new { |h,k| h[k] = {} }

      if @jarcache[jarpath].empty?
        #puts "Caching file entries for #{jarpath}"
        s = Time.now
        zip = java.util.zip.ZipFile.new(jarpath)
        zip.entries.each do |entry|
          #puts "Caching file entries for #{jarpath}: /#{entry.name}"
          # Prefix entry name with "/" because that's what the jar path looks
          # like in jruby: file://some.jar!/some/path
          @jarcache[jarpath]["/" + entry.name] = entry
        end
      end

      entry = @jarcache[jarpath][path]
      #puts "Serving cached file info #{path}: #{entry}"
      return entry
    end
  end
end
