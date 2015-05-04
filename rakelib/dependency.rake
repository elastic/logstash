
namespace "dependency" do
  task "bundler" do
    Rake::Task["gem:require"].invoke("bundler", "~> 1.9.4")
  end

  task "rbx-stdlib" do
    Rake::Task["gem:require"].invoke("rubysl", ">= 0")
  end # task rbx-stdlib

  task "archive-tar-minitar" do
    Rake::Task["gem:require"].invoke("minitar", ">= 0")
  end # task archive-minitar

  task "stud" do
    Rake::Task["gem:require"].invoke("stud", ">= 0")
  end # task stud

  task "fpm" do
    Rake::Task["gem:require"].invoke("fpm", ">= 0")
  end # task stud

  task "rubyzip" do
    Rake::Task["gem:require"].invoke("rubyzip", ">= 0")
  end # task stud

  task "octokit" do
    Rake::Task["gem:require"].invoke("octokit", ">= 0")
  end # task octokit

  task "gems" do
    Rake::Task["gem:require"].invoke("gems", ">= 0")
  end # task gems

end # namespace dependency
