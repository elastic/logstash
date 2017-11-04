namespace "vendor" do
  def vendor(*args)
    return File.join("vendor", *args)
  end

  task "jruby" do |task, args|
    system('./gradlew downloadAndInstallJRuby')
  end # jruby

  task "all" => "jruby"

  task "system_gem", :jruby_bin, :name, :version do |task, args|
    jruby_bin = args[:jruby_bin]
    name = args[:name]
    version = args[:version]

    IO.popen([jruby_bin, "-S", "gem", "list", name, "--version", version, "--installed"], "r") do |io|
      io.readlines # ignore
    end
    unless $?.success?
      puts("Installing #{name} #{version} because the build process needs it.")
      system(jruby_bin, "-S", "gem", "install", name, "-v", version, "--no-ri", "--no-rdoc")
      raise RuntimeError, $!.to_s unless $?.success?
    end
    task.reenable # Allow this task to be run again
  end

  namespace "force" do
    task "gems" => ["vendor:gems"]
  end

  task "gems", [:bundle] do |task, args|
    require "bootstrap/environment"

    Rake::Task["dependency:bundler"].invoke

    puts("Invoking bundler install...")
    output, exception = LogStash::Bundler.invoke!(:install => true)
    puts(output)
    raise(exception) if exception
  end # task gems
  task "all" => "gems"

  desc "Clean the vendored files"
  task :clean do
    rm_rf(vendor)
  end
end
