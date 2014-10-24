if ENV['USE_RUBY'] != '1'
  if RUBY_ENGINE != "jruby" or Gem.ruby !~ /vendor\/jruby\/bin\/jruby/
    puts "Restarting myself under Vendored JRuby (currently #{RUBY_ENGINE} #{RUBY_VERSION})" 

    # Make sure we have JRuby, then rerun ourselves under jruby.
    Rake::Task["vendor:jruby"].invoke

    jruby = File.join("vendor", "jruby", "bin", "jruby")
    rake = File.join("vendor", "jruby", "bin", "rake")
    exec(jruby, "-S", rake, *ARGV)
  end
end
