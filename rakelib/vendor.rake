namespace "vendor" do
  def vendor(*args)
    return File.join("vendor", *args)
  end

  task "jruby" do |task, args|
    system('./gradlew downloadAndInstallJRuby')
  end # jruby

  task "all" => "jruby"

  namespace "force" do
    task "gems" => ["vendor:gems"]
  end

  task "gems", [:bundle] do |task, args|
    require "bootstrap/environment"

    Rake::Task["dependency:clamp"].invoke
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
