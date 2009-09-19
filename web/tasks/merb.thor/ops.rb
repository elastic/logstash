module Thor::Tasks
  module Merb
    class Collector
      attr_reader :dependencies

      def self.collect(str)
        collector = new
        collector.instance_eval(str)
        collector.dependencies
      end

      def initialize
        @dependencies = []
      end

      def dependency(name, *versions)
        versions.pop if versions.last.is_a?(Hash)
        @dependencies << [name, versions]
      end
    end
    
    class Gem < Thor
      def full_list
        @idx.load_gems_in("gems/specifications")

        @list.map do |name, versions|
          dep = ::Gem::Dependency.new(name, versions)
          spec = @idx.search(dep).last
          unless spec
            self.class.error "A required dependency #{dep} was not found"
            self.class.rollback_trans
          end
          deps = spec.recursive_dependencies(dep, @idx)
          [spec] + deps
        end.flatten.uniq
      end
      
      def rescue_failures(error = StandardError, prc = nil)
        begin
          yield
        rescue error => e
          if prc
            prc.call(e)
          else
            puts e.message
            puts e.backtrace
          end
          self.class.rollback_trans
        end
      end

      def self.begin_trans
        note "Beginning transaction"
        FileUtils.cp_r(Dir.pwd / "gems", Dir.pwd / ".original_gems")
      end

      def self.commit_trans
        note "Committing transaction"
        FileUtils.rm_rf(Dir.pwd / ".original_gems")
      end

      def self.rollback_trans
        if File.exist?(Dir.pwd / ".original_gems")
          note "Rolling back transaction"
          FileUtils.rm_rf(Dir.pwd / "gems")
          FileUtils.mv(Dir.pwd / ".original_gems", Dir.pwd / "gems")
        end
        exit!
      end
      
      private
      def _install(dep)
        @idx.load_gems_in("gems/specifications")
        return if @idx.search(dep).last
        
        installer = ::Gem::DependencyInstaller.new(
          :bin_dir => Dir.pwd / "bin",
          :install_dir => Dir.pwd / "gems",
          :user_install => false)

        begin
          installer.install dep.name, dep.version_requirements
        rescue ::Gem::GemNotFoundException => e
          puts "Cannot find #{dep}"
        rescue ::Gem::RemoteFetcher::FetchError => e
          puts e.message
          puts "Retrying..."
          retry
        end
      end
    end
  end
end