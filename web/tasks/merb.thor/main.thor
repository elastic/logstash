require "rubygems"
require "rubygems/source_index"
require "rubygems/dependency_installer"
require "rubygems/uninstaller"
require "fileutils"
require File.join(File.dirname(__FILE__), "utils")
require File.join(File.dirname(__FILE__), "gem_ext")
require File.join(File.dirname(__FILE__), "ops")

$INSTALLING = []

module Merb
  
  class Gem < Thor
    extend ColorfulMessages
    
    def initialize
      dirs = [Dir.pwd, File.dirname(__FILE__) / ".."]
      root = dirs.find {|d| File.file?(d / "config" / "dependencies.rb")}
      
      if root
        @depsrb = root / "config" / "dependencies.rb"
      else
        self.class.error "dependencies.rb was not found"
        exit!
      end
      
      FileUtils.mkdir_p(Dir.pwd / "gems")
      
      @list = Collector.collect(File.read(@depsrb))
      @idx = ::Gem::SourceIndex.new.load_gems_in("gems/specifications")
    end
    
    def list
      require "pp"
      pp @list
    end
    
    desc "redeploy", "Syncs up gems/cache with gems/gems. All gems in the cache " \
                     "that are not already installed will be installed from the " \
                     "cache. All installed gems that are not in the cache will " \
                     "be uninstalled."
    def redeploy
      gem_dir = Dir.pwd / "gems" / "gems"
      cache_dir = Dir.pwd / "gems" / "cache"
      
      gems  = Dir[gem_dir / "*"].map!  {|n| File.basename(n)}
      cache = Dir[cache_dir / "*.gem"].map! {|n| File.basename(n, ".gem")}
      new_gems = cache - gems
      outdated = gems - cache
      idx = ::Gem::SourceIndex.new
      idx.load_gems_in(Dir.pwd / "gems" / "specifications")

      new_gems.each do |g|
        installer = ::Gem::Installer.new(cache_dir / "#{g}.gem",
          :bin_dir => Dir.pwd / "bin",
          :install_dir => Dir.pwd / "gems",
          :ignore_dependencies => true,
          :user_install => false,
          :wrappers => true,
          :source_index => idx)
            
        installer.install
      end
      
      outdated.each do |g|
        /(.*)\-(.*)/ =~ g
        name, version = $1, $2
        uninstaller = ::Gem::Uninstaller.new(name,
          :version => version,
          :bin_dir => Dir.pwd / "bin",
          :install_dir => Dir.pwd / "gems",
          :ignore => true,
          :executables => true
        )
        uninstaller.uninstall
      end
    end
    
    desc "confirm", "Confirm the current setup. merb:gem:install will " \
                    "automatically run this task before committing the " \
                    "changes it makes."
    def confirm(gems = @list)
      ::Gem.path.replace([Dir.pwd / "gems"])
      ::Gem.source_index.load_gems_in(Dir.pwd / "gems" / "specifications")
      
      self.class.info "Confirming configuration..."
      
      ::Gem.loaded_specs.clear
      
      begin
        gems.each do |name, versions|
          versions ||= []
          ::Gem.activate name, *versions
        end
      rescue ::Gem::LoadError => e
        self.class.error "Configuration could not be confirmed: #{e.message}"
        self.class.rollback_trans
      end
      self.class.info "Confirmed"
    end
    
    desc 'install', 'Sync up your bundled gems with the list in config/dependencies.rb'
    def install(*gems)
      if gems.empty?
        gems = @list
      else
        gems = gems.map {|desc| name, *versions = desc.split(" ") }
      end
      
      $GEMS = gems
      
      self.class.begin_trans
      
      gems.each do |name, versions|
        dep = ::Gem::Dependency.new(name, versions || [])
        unless @idx.search(dep).empty?
          next
        end
        
        rescue_failures do
          $INSTALLING = dep
          _install(dep)
        end
      end

      gem_dir = Dir.pwd / "gems" / "gems"
      installed_gems  = Dir[gem_dir / "*"].map!  {|n| File.basename(n)}
      
      list = full_list.map {|x| x.full_name}.compact
      
      (installed_gems - list).each do |g|
        /^(.*)\-(.*)$/ =~ g
        name, version = $1, $2
        uninstaller = ::Gem::Uninstaller.new(name,
          :version => version,
          :bin_dir => (Dir.pwd / "bin").to_s,
          :install_dir => (Dir.pwd / "gems").to_s,
          :ignore => true,
          :executables => true
        )
        uninstaller.uninstall
      end
      
      confirm(gems)
      
      self.class.commit_trans
    end
  end
end