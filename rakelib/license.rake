require "rubygems/specification"
require "bootstrap/environment"
require_relative "default_plugins"
require 'rubygems'

namespace "license" do

  SKIPPED_DEPENDENCIES = [
    "logstash-core-plugin-api"
  ]

  GEM_INSTALL_PATH = File.join(LogStash::Environment.logstash_gem_home, "gems")

  NOTICE_FILE_PATH = File.join(LogStash::Environment::LOGSTASH_HOME, "NOTICE.TXT")

  desc "Generate a license/notice file for default plugin dependencies"
  task "generate-notice-file" => ["bootstrap", "plugin:install-default"] do
    puts("[license:generate-notice-file] Generating notice file for default plugin dependencies")
    generate_notice_file
  end

  def generate_notice_file
    File.open(NOTICE_FILE_PATH,'w') do |file|
      begin
        add_logstash_header(file)
        add_dependencies_licenses(file)
      rescue => e
        raise "Unable to generate notice file, #{e}"
      end
    end
  end

  def add_logstash_header(notice_file)
    copyright_year = Time.now.year
    notice_file << "Logstash\n"
    notice_file << "Copyright 2012-#{copyright_year} Elasticsearch\n"
    notice_file << "\nThis product includes software developed by The Apache Software Foundation (http://www.apache.org/).\n"
    notice_file << "\n==========================================================================\n"
    notice_file << "Third party libraries bundled by the Logstash project:\n\n"
  end

  def add_dependencies_licenses(notice_file)
    # to keep track of all the plugins we've traversed
    seen_dependencies = Hash.new
    LogStash::RakeLib::DEFAULT_PLUGINS.each do |plugin|
      gemspec = Gem::Specification.find_all_by_name(plugin)[0]
      if gemspec.nil?
        raise "Fail to generate `NOTICE.TXT` file because #{plugin} was not found in the installed plugins specifications"
      end
      gemspec.runtime_dependencies.each do |dep|
        name = dep.name
        next if SKIPPED_DEPENDENCIES.include?(name) || seen_dependencies.key?(name)
        seen_dependencies[name] = true
        # ignore all the runtime logstash-* plugin dependencies
        next if name.start_with?("logstash")
        path = gem_home(dep.to_spec)
        dep.to_spec.licenses.each do |license|
          notice = ""
          license = ""
          Dir.glob(File.join(path, '*LICENSE*')) do |path|
            notice << File.read(path)
            notice << "\n"
          end
          Dir.glob(File.join(path, '*NOTICE*')) do |path|
            license << File.read(path)
            license << "\n"
          end

          if !notice.empty? || !license.empty?
            notice_file << "==========================================================================\n"
            notice_file << "RubyGem: #{name} Version: #{dep.to_spec.version}\n"
            notice_file << notice
            notice_file << license
          end
        end
      end
    end
  end

  def gem_home(spec)
    spec_base_name = "#{spec.name}-#{spec.version}"
    if spec.platform == "java"
      spec_base_name += "-java"
    end
    File.join(GEM_INSTALL_PATH, "#{spec_base_name}")
  end
end
