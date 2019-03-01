namespace "dependency" do
  task "bundler" do
    Rake::Task["gem:require"].invoke("bundler", "~> 1.17.1")
  end
end # namespace dependency
