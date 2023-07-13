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

class LogStash::PluginManager::Command < Clamp::Command
  def gemfile
    @gemfile ||= LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, 'r+')).load
  end

  # If set in debug mode we will raise an exception and display the stacktrace
  def report_exception(readable_message, exception)
    if debug?
      raise exception
    else
      signal_error("#{readable_message}, message: #{exception.message}")
    end
  end

  def display_bundler_output(output)
    if debug? && output
      # Display what bundler did in the last run
      $stderr.puts("Bundler output")
      $stderr.puts(output)
    end
  end

  # Each plugin install for a gemfile create a path with a unique id.
  # we must clear what is not currently used in the
  def remove_unused_locally_installed_gems!
    used_path = gemfile.locally_installed_gems.collect { |gem| gem.options[:path] }

    Dir.glob(File.join(LogStash::Environment::LOCAL_GEM_PATH, '*')) do |path|
      FileUtils.rm_rf(relative_path(path)) if used_path.none? { |p| p.start_with?(relative_path(path)) }
    end
  end

  def relative_path(path)
    require "pathname"
    ::Pathname.new(path).relative_path_from(::Pathname.new(LogStash::Environment::LOGSTASH_HOME)).to_s
  end

  def debug?
    ENV["DEBUG"]
  end
end
