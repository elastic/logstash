#!/usr/bin/env ruby
# Deletes changelog fragment files that have already been captured in a bundle.
#
# Run this once you are satisfied with the generated release notes for a version.
# It is intentionally separate from generate_release_notes_md.rb so that
# generation remains re-runnable (e.g. when a late-breaking change arrives
# after the first draft).
#
# Usage:
#   ruby prune_changelog_fragments.rb
#   ruby prune_changelog_fragments.rb --dry-run

require 'yaml'
require 'set'

CHANGELOG_FRAGMENTS_PATH = "docs/changelog"
CHANGELOG_BUNDLES_PATH   = "docs/release-notes/changelog-bundles"

dry_run = ARGV.include?('--dry-run')

bundle_files = Dir.glob("#{CHANGELOG_BUNDLES_PATH}/*.yml").sort
if bundle_files.empty?
  puts "No bundle files found in #{CHANGELOG_BUNDLES_PATH} — nothing to prune."
  exit 0
end

bundled_prs = bundle_files.flat_map do |path|
  bundle = YAML.safe_load(File.read(path), permitted_classes: [Integer, Time])
  Array(bundle['changelogs']).map { |c| c['pr'].to_s }
rescue => e
  $stderr.puts "Warning: skipping bundle #{path}: #{e.message}"
  []
end.to_set

pruned = []
Dir.glob("#{CHANGELOG_FRAGMENTS_PATH}/*.yaml").sort.each do |path|
  pr = File.basename(path, '.yaml')
  next unless bundled_prs.include?(pr)

  if dry_run
    puts "Would delete: #{path}"
  else
    File.delete(path)
    puts "Deleted: #{path}"
  end
  pruned << path
end

if pruned.empty?
  puts "No fragment files matched bundled PRs — nothing pruned."
else
  puts "#{dry_run ? 'Would prune' : 'Pruned'} #{pruned.size} fragment(s)."
  puts "Stage and commit the deletions with: git add docs/changelog/ && git commit -m 'Prune changelog fragments for released versions'" unless dry_run
end
