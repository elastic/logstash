#!/usr/bin/env ruby

require "rubygems/package"

gemspec = ARGV.shift

spec = Gem::Specification.load(gemspec)
deps = [spec.development_dependencies, spec.runtime_dependencies].flatten

# target for now
target = "vendor/bundle/jruby/1.9/"

deps.each do |dep|
  cmd = "gem install --install-dir #{target} #{dep.name} -v '#{dep.requirement}'"
  puts cmd
  system(cmd)
end

#specs_and_sources, errors = Gem::SpecFetcher.fetcher.fetch_with_errors(deps.first, true, true, false)
#require "pry"; binding.pry



