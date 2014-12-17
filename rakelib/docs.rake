namespace "docs" do

  task "generate" do
    Rake::Task['docs:install-plugins'].invoke
    Rake::Task['docs:generate-docs'].invoke
    Rake::Task['docs:generate-index'].invoke
  end

  task "generate-docs" do
    list = Dir.glob("vendor/bundle/jruby/1.9/gems/logstash-*/lib/logstash/{input,output,filter,codec}s/*.rb").join(" ")
    cmd = "bin/logstash docgen -o asciidoc_generated #{list}"
    system(cmd)
  end

  task "generate-index" do
    list = [ 'inputs', 'outputs', 'filters', 'codecs' ]
    list.each do |type|
      cmd = "ruby docs/asciidoc_index.rb asciidoc_generated #{type}"
      system(cmd)
    end
  end


  task "install-plugins" => [ "dependency:bundler", "dependency:octokit" ] do
    
    # because --path creates a .bundle/config file and changes bundler path
    # we need to remove this file so it doesn't influence following bundler calls
    FileUtils.rm_rf(::File.join(LogStash::Environment::LOGSTASH_HOME, "tools/.bundle"))

    10.times do
      begin
        ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
        ENV["BUNDLE_PATH"] = LogStash::Environment.logstash_gem_home
        ENV["BUNDLE_GEMFILE"] = "tools/Gemfile.all"
        Bundler.reset!
        Bundler::CLI.start(LogStash::Environment.bundler_install_command("tools/Gemfile.all", LogStash::Environment::BUNDLE_DIR))
        break
      rescue => e
        # for now catch all, looks like bundler now throws Bundler::InstallError, Errno::EBADF
        puts(e.message)
        puts("--> Retrying install-defaults upon exception=#{e.class}")
        sleep(1)
      end
    end

    # because --path creates a .bundle/config file and changes bundler path
    # we need to remove this file so it doesn't influence following bundler calls
    FileUtils.rm_rf(::File.join(LogStash::Environment::LOGSTASH_HOME, "tools/.bundle"))
  end

end
