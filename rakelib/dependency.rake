
namespace "dependency" do
  task "bundler" do
    Rake::Task["gem:require"].invoke("bundler", ">= 1.3.5", LogStash::Environment.logstash_gem_home)
    require "bundler/cli"
    require_relative "bundler_patch"
  end

  task "rbx-stdlib" do
    Rake::Task["gem:require"].invoke("rubysl", ">= 0", LogStash::Environment.logstash_gem_home)
  end # task rbx-stdlib

  task "archive-tar-minitar" do
    Rake::Task["gem:require"].invoke("minitar", ">= 0", LogStash::Environment.logstash_gem_home)
  end # task archive-minitar

  task "stud" do
    Rake::Task["gem:require"].invoke("stud", ">= 0", LogStash::Environment.logstash_gem_home)
  end # task stud

  task "fpm" do
    Rake::Task["gem:require"].invoke("fpm", ">= 0", LogStash::Environment.logstash_gem_home)
  end # task stud
end # namespace dependency
