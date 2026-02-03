# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

namespace "extract" do
  desc "Extract versions from a Logstash artifact directory"
  task :artifact_versions, [:artifact_dir, :output_file] do |t, args|
    require 'fileutils'

    artifact_dir = args[:artifact_dir] || raise("artifact_dir argument required")
    output_file = args[:output_file] || "output.csv"

    # Resolve to absolute path before changing directories
    artifact_dir = File.expand_path(artifact_dir)
    output_file = File.expand_path(output_file)

    unless File.directory?(artifact_dir)
      raise "Error: #{artifact_dir} is not a directory"
    end

    script_dir = File.join(Dir.pwd, ".buildkite", "scripts", "snyk", "artifact-scan")
    extract_script = File.join(script_dir, "extract_versions.rb")

    unless File.exist?(extract_script)
      raise "Error: extraction script not found at #{extract_script}"
    end

    begin
      require 'zip'
    rescue LoadError => e
      raise "Error: rubyzip gem not available. Ensure 'bootstrap' task has run. (#{e.message})"
    end

    puts "Extracting versions from #{artifact_dir}..."
    Dir.chdir(script_dir) do
      # Set ARGV for the script
      ARGV.clear
      ARGV << artifact_dir << output_file
      load extract_script
    end

    sbom_file = output_file.sub('.csv', '_sbom.json')

    puts "\nGenerated files:"
    puts "  - #{output_file}"
    puts "  - #{output_file.sub('.csv', '_duplicates.csv')}"
    puts "  - #{sbom_file}"
    puts "\nReady for Snyk scanning with: snyk sbom test --experimental --file=#{sbom_file}"
  end

  desc "Clean artifact extraction output files"
  task :clean do
    FileUtils.rm_f(Dir.glob("output*.csv"))
    FileUtils.rm_f(Dir.glob("output*.json"))
    puts "Cleaned extraction output files"
  end
end
