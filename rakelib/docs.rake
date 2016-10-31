namespace "docs" do

  desc "Generate documentation for all plugins"
  task "generate" do
    Rake::Task['plugin:install-all'].invoke
    Rake::Task['docs:generate-docs'].invoke
    Rake::Task['docs:generate-index'].invoke
  end

  task "generate-docs" do
    require "bootstrap/environment"
    pattern = "#{LogStash::Environment.logstash_gem_home}/gems/logstash-*/lib/logstash/{input,output,filter,codec}s/[!base]*.rb"
    puts "Generated asciidoc is under dir LS_HOME/asciidoc_generated"
    files = Dir.glob(pattern)
    files.each do | file|
      begin
        cmd = "bin/logstash docgen -o asciidoc_generated #{file}"
        # this is a bit slow, but is more resilient to failures
        system(cmd)
      rescue
        # there are some plugins which will not load, so move on..
        puts "Unable to generate docs for file #{file}"
        next
      end
    end
  end

  task "generate-index" do
    list = [ 'inputs', 'outputs', 'filters', 'codecs' ]
    list.each do |type|
      cmd = "bin/bundle exec ruby docs/asciidoc_index.rb asciidoc_generated #{type}"
      system(cmd)
    end
  end
end
