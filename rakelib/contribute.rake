
namespace "contribute" do
  task "watch-all" do
    Rake::Task["gem:require"].invoke("octokit", ">= 0", ENV["GEM_HOME"])
    require 'octokit'
    require 'io/console' #for password input
    #Connect to Github
    print "Please enter your github login: "
    login = STDIN.gets.chomp
    print "Please enter your github password: "
    pass = STDIN.noecho(&:gets).chomp
    puts ""
    client=Octokit::Client.new(:login => login, :password => pass)
    client.auto_paginate = true
    client.organization_repositories("logstash-plugins").each do |plugin_repo|
      success = client.update_subscription("logstash-plugins/#{plugin_repo.name}", {subscribed: true})
      if success
      	puts "Successfully added you as subscriber to logstash-plugins/#{plugin_repo.name}"
      else
      	puts "Failure in adding you as subscriber to logstash-plugins/#{plugin_repo.name}"
      end
    end
  end

  task "star-all" do
    Rake::Task["gem:require"].invoke("octokit", ">= 0", ENV["GEM_HOME"])
    require 'octokit'
    #Connect to Github
    print "Please enter your github login: "
    login = STDIN.gets.chomp
    print "Please enter your github password: "
    pass = STDIN.noecho(&:gets).chomp
    puts ""
    client=Octokit::Client.new(:login => login, :password => pass)
    client.auto_paginate = true
    client.organization_repositories("logstash-plugins").each do |plugin_repo|
      success = client.star("logstash-plugins/#{plugin_repo.name}")
      if success
      	puts "Successfully starred logstash-plugins/#{plugin_repo.name} for you"
      else
      	puts "Failure in starring logstash-plugins/#{plugin_repo.name} for you"
      end
    end
  end
end # namespace dependency
