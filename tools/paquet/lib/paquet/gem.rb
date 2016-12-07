# encoding: utf-8
require "paquet/dependency"
require "paquet/shell_ui"
require "paquet/utils"

module Paquet
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
      Paquet::ui.info("Cleaning existing target path: #{@target_path}")

      FileUtils.rm_rf(@target_path)
      FileUtils.mkdir_p(@target_path)

      download_gems(collect_required_gems)
    end

    def size
      @gems.size
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

        Paquet::ui.info("Vendoring: #{name}, downloading: #{source}")
        Paquet::Utils::download_file(source, destination)
      end
    end
  end
end
