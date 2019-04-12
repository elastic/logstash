namespace "dependency" do
  task "bundler" do
    Rake::Task["gem:require"].invoke("bundler", "~> 1.17.3")
  end
end # namespace dependency
