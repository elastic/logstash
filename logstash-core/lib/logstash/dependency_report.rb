# encoding: utf-8
Thread.abort_on_exception = true
Encoding.default_external = Encoding::UTF_8
$DEBUGLIST = (ENV["DEBUG"] || "").split(",")

require "clamp"
require "logstash/namespace"
require "rubygems"
require "jar_dependencies"

class LogStash::DependencyReport < Clamp::Command
  option [ "--csv" ], "OUTPUT_PATH", "The path to write the dependency report in csv format.", :required => true

  def execute
    dependencies = []
    dependencies += Gem::Specification.all.collect do |gem|
      [gem.name, gem.version.to_s, gem.homepage, gem.licenses.join("|")]
    end
    dependencies += Gem::Specification.all.select { |g| g.requirements && g.requirements.any? }.collect do |gem|
      gem.requirements.each do |requirement|
        next unless requirement =~ /^jar /
        jar = Jars::GemspecArtifacts::Artifact.new(requirement)
        ["#{jar.group_id}:#{jar.artifact_id}", jar.version, "unknown", "unknown"]
      end
    end

    require "pry"
    binding.pry

  end # def self.main
end
