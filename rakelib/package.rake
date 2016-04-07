namespace "package" do

  task "bundle" do
    system("bin/logstash-plugin", "pack")
    raise(RuntimeError, $!.to_s) unless $?.success?
  end

  desc "Build a package with the default plugins, including dependencies, to be installed offline"
  task "plugins-default" => ["test:install-default", "bundle"]

  desc "Build a package with all the plugins, including dependencies, to be installed offline"
  task "plugins-all" => ["test:install-all", "bundle"]
end
