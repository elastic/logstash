# encoding: utf-8
require "bundler"
require "rake"
require "rake/tasklib"
require "fileutils"
require "net/http"

# This class add new rake methods to a an existing ruby gem,
# these methods allow developpers to create a Uber gem, a uber gem is
# a tarball that contains the current gems and one or more of his dependencies.
#
# This Tool will take care of looking at the current dependency tree defined in the Gemspec and the gemfile
# and will traverse all graph and download the gem file into a specified directory.
#
# By default, the tool wont fetch everything and the developper need to declare what gems he want to download.
module Paquet
  class ShellUi
    def debug(message)
      report_message(:debug, message) if debug?
    end

    def info(message)
      report_message(:info, message)
    end

    def report_message(level, message)
      puts "[#{level}]: #{message}"
    end

    def debug?
      ENV["DEBUG"]
    end
  end

  def ui
    @logger ||= ShellUi.new
  end

  class Gem
    RUBYGEMS_URI = "https://rubygems.org/downloads"

    attr_reader :gems, :ignores

    def initialize(target_path)
      @target_path = target_path
      @gems = []
      @ignores = []
    end

    def add(name)
      @gems << name
    end

    def ignore(name)
      @ignores << name
    end

    def pack
      ui.info("Cleaning existing target path: #{@target_path}")
      FileUtils.rm_rf(@target_path)
      FileUtils.mkdir_p(@target_path)

      download_gems(collect_required_gems)
    end

    def size
      @gems.size
    end

    private
    class Dependency
      attr_reader :name, :version, :platform

      def initialize(name, version, platform)
        @name = name
        @version = version
        @platform = platform
      end

      def to_s
        "#{name}-#{version}"
      end

      def ruby?
        platform == "ruby"
      end
    end

    def ignore?(name)
      ignores.include?(name)
    end

    def collect_required_gems()
      candidates = []
      @gems.each do |name|
        candidates += resolve_dependencies(name)
      end
      candidates.flatten
    end

    def resolve_dependencies(name)
      return [] if ignore?(name)

      spec = ::Gem::Specification.find_by_name(name)
      current_dependency = Dependency.new(name, spec.version, spec.platform)
      dependencies = spec.dependencies.select { |dep| dep.type == :runtime }

      if dependencies.size == 0
        [current_dependency]
      else
        [dependencies.collect { |spec| resolve_dependencies(spec.name) }, current_dependency].flatten.uniq { |s| s.name }
      end
    end

    def download_gems(required_gems)
      required_gems
        .collect { |gem| gem.ruby? ? "#{gem.name}-#{gem.version}.gem" : "#{gem.name}-#{gem.version}-#{gem.platform}.gem" }
        .uniq
        .each do |name|
          source = "#{RUBYGEMS_URI}/#{name}"
          destination = File.join(@target_path, name)

          ui.info("Vendoring: #{name}, downloading: #{source}")
          download_file(source, destination)
      end
    end

    def download_file(source, destination, counter = 10)
      raise "Too many redirection" if counter == 0

      f = File.open(destination, "w")

      begin
        uri = URI.parse(source)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        response = http.get(uri.path)

        case response
        when Net::HTTPSuccess
          f.write(response.body)
        when Net::HTTPRedirection
          download_file(response['location'], destination, counter)
        else
          raise "Response not handled: #{response.class}"
        end

      ensure
        f.close
      end
    end
  end

  class Task < Rake::TaskLib
    def initialize(target_path, &block)
      @gem = Gem.new(target_path)

      instance_eval(&block)

      namespace :paquet do
        desc "Build a pack with #{@gem.size} gems: #{@gem.gems.join(",")}"
        task :vendor do
          @gem.pack
        end
      end
    end

    def pack(name)
      @gem.add(name)
    end

    def ignore(name)
      @gem.ignore(name)
    end
  end
end
