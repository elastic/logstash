if ENV['USE_RUBY'] != '1'
  if RUBY_ENGINE != "jruby" or Gem.ruby !~ /vendor\/jruby\/bin\/jruby/
    puts "Restarting myself under Vendored JRuby (currently #{RUBY_ENGINE} #{RUBY_VERSION})" if ENV['DEBUG']

    if ["mingw32", "mswin32"].include?(RbConfig::CONFIG["host_os"])
      # Use our own SSL certs when on Windows
      # There seems to be no other workaround other than monkeypatching.
      # If we're on windows, we have to provide a correct SSL CA cert for validating
      # rubygems.org ssl certificate.
      # Lots of folks report this problem: https://gist.github.com/luislavena/f064211759ee0f806c88
      # https://github.com/elasticsearch/logstash/issues/2402
      class Gem::Request
        def add_rubygems_trusted_certs(store)
          __ssl_cert_files.each do |ssl_cert|
            store.add_file ssl_cert
          end
        end

        def __ssl_cert_files
          return @__ssl_cert_files if @__ssl_cert_files
          ssl_cert_glob = File.join(File.dirname(__FILE__), "..", "tools", "ca", "*.pem")
          @__ssl_cert_files = Dir.glob(ssl_cert_glob).to_a
        end
      end
    end

    # Make sure we have JRuby, then rerun ourselves under jruby.
    Rake::Task["vendor:jruby"].invoke
    jruby = File.join("vendor", "jruby", "bin", "jruby")
    rake = File.join("vendor", "jruby", "bin", "rake")

    # if required at this point system gems can be installed using the system_gem task, for example:
    # Rake::Task["vendor:system_gem"].invoke(jruby, "ffi", "1.9.6")

    exec(jruby, "-J-Xmx1g", "-S", rake, *ARGV)
  end
end

def discover_rake()
  Dir.glob('vendor', 'bundle', 'rake')
end
