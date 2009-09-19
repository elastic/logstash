$: << File.join("doc")
require 'rubygems'
require 'rdoc/rdoc'
require 'fileutils'
require 'erb'

module Merb
  
  class GemNotFoundException < Exception
  end
  
  module DocMethods
    def setup_gem_path
      if File.directory?(gems_dir = File.join(File.dirname(__FILE__), 'gems'))
        $BUNDLE = true; Gem.clear_paths; Gem.path.unshift(gems_dir)
      end
    end
    
    def get_more
      libs = []
      more_library = find_library("merb-more")
      File.open("#{more_library}/lib/merb-more.rb").read.each_line do |line|
        if line['require']
          libs << line.gsub("require '", '').gsub("'\n", '')
        end
      end
      return libs
    end
    
    def generate_documentation(file_list, destination, arguments = [])
      output_dir = File.join("/../doc", "rdoc", destination)
      FileUtils.rm_rf(output_dir)
      
      arguments += [
        "--fmt", "merb",
        "--op", output_dir
      ]
      RDoc::RDoc.new.document(arguments + file_list)
      AdvancedDoc.new.index
    end
    
    def find_library(directory_snippet)
      gem_dir = nil
      Gem.path.find do |path|
        dir = Dir.glob("#{path}/gems/#{directory_snippet}*") 
        dir.empty? ? false : gem_dir = dir.last
      end
      raise GemNotFoundException if gem_dir.nil?
      return gem_dir
    end
    
    def get_file_list(directory_snippet)
      gem_dir = find_library(directory_snippet)
      files = Dir.glob("#{gem_dir}/**/lib/**/*.rb")
      files += ["#{gem_dir}/README"] if File.exists?("#{gem_dir}/README")
      return  files
    end
  end
  
  class AdvancedDoc < Thor
    
    group 'core'
    include DocMethods
    
    def initialize
      super
      setup_gem_path
    end
    
    desc 'index', "Regenerate the index file for your framework documentation"
    def index
      @directories = Dir.entries(File.join(File.dirname(__FILE__) + "/../", "doc", "rdoc"))
      @directories.delete(".")
      @directories.delete("..")
      @directories.delete("generators")
      @directories.delete("index.html")
      index_template = File.read(File.join("doc", "rdoc", "generators", "template", "merb", "index.html.erb"))
      
      File.open(File.join("doc", "rdoc", "index.html"), "w") do |file|
        file.write(ERB.new(index_template).result(binding))
      end
    end
    
    desc 'plugins', 'Generate the rdoc for each merb-plugins seperatly'
    def plugins
      libs = ["merb_activerecord", "merb_builder", "merb_jquery", "merb_laszlo", "merb_parts", "merb_screw_unit", "merb_sequel", "merb_stories", "merb_test_unit"]
      
      libs.each do |lib|
        options[:gem] = lib
        gem
      end
    end
    
    desc 'more', 'Generate the rdoc for each merb-more gem seperatly'
    def more
      libs = get_more
      libs.each do |lib|
        options[:gem] = lib
        gem
      end
    end
    
    desc 'core', 'Generate the rdoc for merb-core'
    def core
      options[:gem] = "merb-core"
      gem
    end
    
    desc 'gem', 'Generate the rdoc for a specific gem'
    method_options "--gem" => :required
    def gem
      file_list = get_file_list(options[:gem])
      readme = File.join(find_library("merb-core"), "README")
      generate_documentation(file_list, options[:gem], ["-m", readme])
    rescue GemNotFoundException
      puts "Can not find the gem in the gem path #{options[:gem]}"
    end
    
  end
  
  class Doc < Thor
    
    include DocMethods
    
    def initialize
      super
      setup_gem_path
      
    end
    
    desc 'stack', 'Generate the rdoc for merb-core, merb-more merged together'
    def stack
      libs = ["merb"]
            
      file_list = []
      libs.each do |gem_name|
        begin
          file_list += get_file_list(gem_name)
        rescue GemNotFoundException
          puts "Could not find #{gem_name} in #{Gem.path}.  Continuing with out it."
        end
      end
      readme = File.join(find_library("merb"), "README")
      generate_documentation(file_list, "stack", ["-m", readme])
    end
    
  end
  
end