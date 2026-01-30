#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'securerandom'
require 'time'
require 'zip'

# Extracts version info from JARs and gemspecs with confidence scoring
#
# Usage: bundle exec ruby extract_versions.rb <directory> [output.csv]

def generate_sbom(results, output_file)
  components = []

  results.each do |r|
    next if r[:version] == 'unknown' || r[:normalized_version] == 'unknown'

    component = { type: 'library', name: r[:name], version: r[:version] }

    # Generate PURL based on type
    if r[:type] == 'gem'
      component[:purl] = "pkg:gem/#{r[:name]}@#{r[:version]}"
    else
      if r[:group_id] && r[:artifact_id]
        group, artifact = r[:group_id], r[:artifact_id]
      elsif r[:name].include?(':')
        group, artifact = r[:name].split(':', 2)
      else
        group, artifact = r[:name], r[:name]
      end
      component[:purl] = "pkg:maven/#{group}/#{artifact}@#{r[:version]}"
      component[:group] = group
      component[:name] = artifact
    end

    # Add evidence of location
    component[:properties] = [
      { name: 'filepath', value: r[:filepath] },
      { name: 'confidence', value: r[:confidence] },
      { name: 'sources', value: r[:sources] }
    ]

    components << component
  end

  sbom = {
    bomFormat: 'CycloneDX',
    specVersion: '1.5',
    serialNumber: "urn:uuid:#{SecureRandom.uuid}",
    version: 1,
    metadata: {
      timestamp: Time.now.utc.iso8601,
      tools: [
        {
          vendor: 'custom',
          name: 'extract_versions.rb',
          version: '1.0.0'
        }
      ],
      component: {
        type: 'application',
        name: 'logstash',
        version: 'extracted'
      }
    },
    components: components
  }

  File.write(output_file, JSON.pretty_generate(sbom))
end

class VersionExtractor
  MANIFEST_VERSION_KEYS = %w[
    Implementation-Version
    Bundle-Version
    Specification-Version
  ].freeze

  # Classifiers/suffixes to strip for normalization
  VERSION_SUFFIXES = %w[
    -jre .jre -java -GA .GA -SNAPSHOT -Final .Final
    -release-\d+ -incubating -alpha -beta -rc\d*
  ].freeze

  def initialize(root_dir)
    @root_dir = root_dir
  end

  def extract_all
    results = []
    results.concat(extract_jars)
    results.concat(extract_gems)
    results
  end

  private

  # Normalize version for comparison
  # "33.1.0-jre" -> "33.1.0", "2.2" -> "2.2.0", "3.24.0.GA" -> "3.24.0"
  def normalize_version(v)
    return nil if v.nil? || v.empty?

    normalized = v.dup

    # Strip known suffixes
    VERSION_SUFFIXES.each do |suffix|
      normalized.gsub!(/#{suffix}$/i, '')
    end

    # Normalize x.y to x.y.0
    if normalized =~ /^\d+\.\d+$/
      normalized = "#{normalized}.0"
    end

    # Handle Derby format: 10.15.2000001.??? -> 10.15.2.1
    # Derby encodes a.b.c.d as a.b.(c*1000000 + d).???
    if normalized =~ /^(\d+)\.(\d+)\.(\d+)\.\?\?\?$/
      major, minor, encoded = $1, $2, $3.to_i
      patch = encoded / 1000000
      build = encoded % 1000000
      if build > 0
        normalized = "#{major}.#{minor}.#{patch}.#{build}"
      else
        normalized = "#{major}.#{minor}.#{patch}.0"
      end
    end

    normalized
  end

  # --- JAR extraction ---

  def extract_jars
    results = []
    jar_files = Dir.glob(File.join(@root_dir, '**', '*.jar'))

    jar_files.each do |jar_path|
      jar_results = extract_jar_versions(jar_path)
      results.concat(jar_results)
    end

    results
  end

  def extract_jar_versions(jar_path)
    sources = {}
    pom_entries = []

    # Parse filename
    filename_info = parse_jar_filename(File.basename(jar_path))
    if filename_info[:version]
      sources[:filename] = filename_info[:version]
    end

    begin
      Zip::File.open(jar_path) do |zip|
        # Find all pom.properties
        zip.each do |entry|
          if entry.name =~ %r{META-INF/maven/(.+)/(.+)/pom\.properties$}
            group_id, artifact_id = $1, $2
            content = entry.get_input_stream.read
            version = parse_pom_properties(content)[:version]
            if version
              pom_entries << { group_id: group_id, artifact_id: artifact_id, version: version }
            end
          end
        end

        # Get MANIFEST.MF
        manifest_entry = zip.find_entry('META-INF/MANIFEST.MF')
        if manifest_entry
          content = manifest_entry.get_input_stream.read
          manifest_version = parse_manifest(content)
          sources[:manifest] = manifest_version if manifest_version
        end
      end
    rescue Zip::Error => e
      sources[:error] = e.message
    rescue => e
      sources[:error] = e.message
    end

    relative_path = relative(jar_path)

    # If no version found, try to infer from parent gem directory
    if sources.empty? || (sources.keys == [:error])
      gem_version = infer_version_from_gem_path(jar_path)
      sources[:inferred_from_gem_path] = gem_version if gem_version
    end

    # If multiple pom.properties, treat as shaded JAR - report each bundled dep
    if pom_entries.size > 1
      results = []

      # Report the main JAR itself
      main_name = filename_info[:name] || File.basename(jar_path, '.jar')
      main_result = build_result(
        type: 'jar',
        name: main_name,
        sources: sources,
        filepath: relative_path
      )
      results << main_result

      # Report each shaded dependency
      pom_entries.each do |pom|
        shaded_sources = {
          "pom.properties[#{pom[:group_id]}:#{pom[:artifact_id]}]" => pom[:version]
        }
        results << build_result(
          type: 'jar-shaded',
          name: "#{pom[:group_id]}:#{pom[:artifact_id]}",
          sources: shaded_sources,
          filepath: relative_path
        )
      end

      results
    elsif pom_entries.size == 1
      pom = pom_entries.first
      jar_basename = File.basename(jar_path, '.jar').downcase
      pom_artifact = pom[:artifact_id].downcase

      # Check if the pom.properties artifact matches the JAR name
      # If not, it's likely a shaded/bundled dependency, not the main artifact
      # Example: xalan-2.7.3.jar contains org.apache.bcel:bcel pom.properties
      if jar_basename.include?(pom_artifact) || pom_artifact.include?(jar_basename.split('-').first)
        sources[:pom_properties] = pom[:version]
        name = filename_info[:name] || pom[:artifact_id]
        [build_result(type: 'jar', name: name, sources: sources, filepath: relative_path, group_id: pom[:group_id], artifact_id: pom[:artifact_id])]
      else
        # pom.properties doesn't match JAR name - treat as shaded dependency
        results = []
        name = filename_info[:name] || File.basename(jar_path, '.jar')
        results << build_result(type: 'jar', name: name, sources: sources, filepath: relative_path)
        shaded_sources = {
          "pom.properties[#{pom[:group_id]}:#{pom[:artifact_id]}]" => pom[:version]
        }
        results << build_result(
          type: 'jar-shaded',
          name: "#{pom[:group_id]}:#{pom[:artifact_id]}",
          sources: shaded_sources,
          filepath: relative_path
        )
        results
      end
    else
      name = filename_info[:name] || File.basename(jar_path, '.jar')
      [build_result(type: 'jar', name: name, sources: sources, filepath: relative_path)]
    end
  end

  def parse_jar_filename(filename)
    # Handle complex names
    base = filename.sub(/\.jar$/, '')
    parts = base.split('-')

    version_start_idx = nil

    parts.each_with_index do |part, idx|
      next if idx == 0

      if part =~ /^\d+\.\d+\.\d+/
        version_start_idx = idx
        break
      end

      if part =~ /^\d+\.\d+$/
        remaining = parts[(idx + 1)..]
        if remaining.empty? || remaining.all? { |p| p =~ /^(\d+|jre|java|GA|Final|SNAPSHOT|RC\d*|alpha|beta|incubating)$/i }
          version_start_idx = idx
          break
        end
      end
    end

    if version_start_idx && version_start_idx > 0
      name = parts[0...version_start_idx].join('-')
      version = parts[version_start_idx..].join('-')
      { name: name, version: version }
    else
      { name: base, version: nil }
    end
  end

  def parse_pom_properties(content)
    props = {}
    content.each_line do |line|
      if line =~ /^(\w+)=(.+)$/
        props[$1.to_sym] = $2.strip
      end
    end
    props
  end

  def infer_version_from_gem_path(jar_path)
    if jar_path =~ %r{/gems/([^/]+)-(\d+\.\d+[^/]*?)(?:-java)?/}
      return $2
    end
    nil
  end

  def parse_manifest(content)
    content = content.gsub(/\r?\n /, '')

    MANIFEST_VERSION_KEYS.each do |key|
      if content =~ /^#{key}:\s*(.+)$/i
        return $1.strip
      end
    end
    nil
  end

  # --- Gem extraction ---

  def extract_gems
    results = []
    gemspec_files = Dir.glob(File.join(@root_dir, '**', '*.gemspec'))

    gemspec_files.each do |gemspec_path|
      results << extract_gem_version(gemspec_path)
    end

    results
  end

  def extract_gem_version(gemspec_path)
    sources = {}
    filename = File.basename(gemspec_path)

    filename_info = parse_gemspec_filename(filename)
    sources[:filename] = filename_info[:version] if filename_info[:version]

    dir_name = File.basename(File.dirname(gemspec_path))
    dir_info = parse_gem_dirname(dir_name)
    sources[:dirname] = dir_info[:version] if dir_info[:version]

    begin
      content = File.read(gemspec_path)
      content_version = parse_gemspec_content(content)
      sources[:gemspec_content] = content_version if content_version
    rescue => e
      sources[:error] = e.message
    end

    name = filename_info[:name] || dir_info[:name] || filename.sub(/\.gemspec$/, '')

    build_result(
      type: 'gem',
      name: name,
      sources: sources,
      filepath: relative(gemspec_path)
    )
  end

  def parse_gemspec_filename(filename)
    if filename =~ /^(.+?)-(\d+\.\d+[^-]*?)(?:-[a-z]+)?\.gemspec$/
      { name: $1, version: $2 }
    else
      { name: filename.sub(/\.gemspec$/, ''), version: nil }
    end
  end

  def parse_gem_dirname(dirname)
    if dirname =~ /^(.+?)-(\d+\.\d+[^-]*?)(?:-[a-z]+)?$/
      { name: $1, version: $2 }
    else
      { name: dirname, version: nil }
    end
  end

  def parse_gemspec_content(content)
    patterns = [
      /\bs\.version\s*=\s*["']([^"']+)["']/,
      /\bspec\.version\s*=\s*["']([^"']+)["']/,
      /\.version\s*=\s*["']([^"']+)["']/,
      /\bversion\s*=\s*["']([^"']+)["']\.freeze/,
      /\bVERSION\s*=\s*["']([^"']+)["']/,
    ]

    patterns.each do |pattern|
      if content =~ pattern
        version = $1
        return version if version =~ /^\d+\.\d+/
      end
    end

    nil
  end

  # --- Confidence & output ---

  def build_result(type:, name:, sources:, filepath:, group_id: nil, artifact_id: nil)
    error = sources.delete(:error)

    raw_versions = sources.values.compact
    normalized_versions = raw_versions.map { |v| normalize_version(v) }.compact.uniq

    confidence = if normalized_versions.empty?
      'none'
    elsif normalized_versions.size == 1
      sources.size >= 2 ? 'high' : 'medium'
    else
      'conflict'
    end

    version = case confidence
    when 'high', 'medium'
      raw_versions.first
    when 'conflict'
      raw_versions.uniq.join(' vs ')
    else
      'unknown'
    end

    normalized = normalized_versions.size == 1 ? normalized_versions.first : nil

    sources_str = sources.map { |k, v| "#{k}:#{v}" }.join(';')
    sources_str += ";error:#{error}" if error

    {
      type: type,
      name: name,
      version: version,
      normalized_version: normalized || version,
      confidence: confidence,
      sources: sources_str,
      filepath: filepath,
      group_id: group_id,
      artifact_id: artifact_id
    }
  end

  def relative(path)
    path.sub(/^#{Regexp.escape(@root_dir)}\/?/, './')
  end
end

# --- Main ---

if ARGV.empty?
  puts "Usage: #{$0} <directory> [output.csv]"
  exit 1
end

root_dir = ARGV[0]
output_file = ARGV[1] || 'output.csv'

unless Dir.exist?(root_dir)
  puts "Error: #{root_dir} is not a directory"
  exit 1
end

extractor = VersionExtractor.new(root_dir)
results = extractor.extract_all

CSV.open(output_file, 'w') do |csv|
  csv << %w[type name version normalized_version confidence sources filepath]
  results.each do |r|
    csv << [r[:type], r[:name], r[:version], r[:normalized_version], r[:confidence], r[:sources], r[:filepath]]
  end
end

by_name = results.group_by { |r| [r[:type].sub('-shaded', ''), r[:name]] }
duplicates = by_name.select { |_, entries| entries.map { |e| e[:normalized_version] }.uniq.size > 1 }

duplicates_file = output_file.sub(/\.csv$/, '_duplicates.csv')
CSV.open(duplicates_file, 'w') do |csv|
  csv << %w[type name versions count locations]
  duplicates.sort_by { |k, _| k }.each do |(type, name), entries|
    versions = entries.map { |e| e[:normalized_version] }.uniq.sort.join('; ')
    locations = entries.map { |e| "#{e[:normalized_version]}:#{e[:filepath]}" }.join('; ')
    csv << [type, name, versions, entries.size, locations]
  end
end

sbom_file = output_file.sub(/\.csv$/, '_sbom.json')
generate_sbom(results, sbom_file)
