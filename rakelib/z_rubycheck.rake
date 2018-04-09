if ENV['USE_RUBY'] != '1'
  if RUBY_ENGINE != "jruby" or Gem.ruby !~ /vendor\/jruby\/bin\/jruby/
    puts "Restarting myself under Vendored JRuby (currently #{RUBY_ENGINE} #{RUBY_VERSION})" if ENV['DEBUG']

    # Make sure we have JRuby, then rerun ourselves under jruby.
    Rake::Task["vendor:jruby"].invoke
    jruby = File.join("bin", "ruby")
    rake = File.join("vendor", "jruby", "bin", "rake")

    # if required at this point system gems can be installed using the system_gem task, for example:
    # Rake::Task["vendor:system_gem"].invoke(jruby, "ffi", "1.9.6")

    # Ignore Environment JAVA_OPTS
    ENV["JAVA_OPTS"] = ""
    exec(jruby, "-J-Xmx1g", "-S", rake, *ARGV)
  end
end

def discover_rake()
  Dir.glob('vendor', 'bundle', 'rake')
end
