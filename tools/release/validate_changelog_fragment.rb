#!/usr/bin/env ruby
# Validates changelog fragment YAML files under docs/changelog/.
# Usage:
#   ruby validate_changelog_fragment.rb docs/changelog/12345.yaml [...]
#   ruby validate_changelog_fragment.rb --all
#
# Exits non-zero if any fragment is invalid.

require 'yaml'
require 'set'

VALID_TYPES = %w[bug enhancement feature breaking_change deprecation dependency doc].freeze
VALID_AREAS = %w[Pipeline Config Monitoring API Performance Plugins Security Packaging Build Core Docs].freeze

errors = []

files = if ARGV.include?('--all')
  Dir.glob(File.join(__dir__, '../../docs/changelog/*.yaml')).sort
else
  ARGV.reject { |a| a.start_with?('-') }
end

if files.empty?
  puts "No fragment files to validate."
  exit 0
end

files.each do |path|
  basename = File.basename(path, '.yaml')

  unless basename.match?(/\A\d+\z/)
    errors << "#{path}: filename must be a PR number (e.g. 12345.yaml)"
    next
  end

  fragment = YAML.safe_load(File.read(path), permitted_classes: [Integer])

  %w[pr summary area type].each do |field|
    errors << "#{path}: missing required field '#{field}'" unless fragment.key?(field)
  end

  if fragment['pr'] && fragment['pr'].to_s != basename
    errors << "#{path}: 'pr' field (#{fragment['pr']}) does not match filename (#{basename})"
  end

  if fragment['type'] && !VALID_TYPES.include?(fragment['type'])
    errors << "#{path}: invalid type '#{fragment['type']}' — must be one of: #{VALID_TYPES.join(', ')}"
  end

  if fragment['area'] && !VALID_AREAS.include?(fragment['area'])
    errors << "#{path}: invalid area '#{fragment['area']}' — must be one of: #{VALID_AREAS.join(', ')}"
  end

  if fragment['issues'] && !fragment['issues'].is_a?(Array)
    errors << "#{path}: 'issues' must be a list (use [] for none)"
  end

  if fragment['highlight']
    h = fragment['highlight']
    %w[title body].each do |f|
      errors << "#{path}: highlight.#{f} is required when highlight is present" unless h[f]
    end
  end

rescue Psych::SyntaxError => e
  errors << "#{path}: YAML parse error — #{e.message}"
rescue => e
  errors << "#{path}: #{e.message}"
end

if errors.empty?
  puts "All #{files.size} fragment(s) valid."
  exit 0
else
  errors.each { |e| $stderr.puts "ERROR: #{e}" }
  exit 1
end
