if RUBY_ENGINE != "jruby"
  puts "Restarting myself under JRuby (currently #{RUBY_ENGINE} #{RUBY_VERSION})" if $DEBUG

  # Make sure we have JRuby, then rerun ourselves under jruby.
  Rake::Task["vendor:jruby"].invoke
  
  jruby = File.join("vendor", "jruby", "bin", "jruby")
  rake = File.join("vendor", "jruby", "bin", "rake")
  exec(jruby, "-S", rake, *ARGV)
end

