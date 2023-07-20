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

require_relative "pack_command"

class LogStash::PluginManager::Pack < LogStash::PluginManager::PackCommand
  option "--tgz", :flag, "compress package as a tar.gz file", :default => !LogStash::Environment.win_platform?
  option "--zip", :flag, "compress package as a zip file", :default => LogStash::Environment.win_platform?
  option "--[no-]clean", :flag, "clean up the generated dump of plugins", :default => true
  option "--overwrite", :flag, "Overwrite a previously generated package file", :default => false

  def execute
    signal_deprecation_warning_for_pack

    puts("Packaging plugins for offline usage")

    validate_target_file
    LogStash::Bundler.invoke!({:package => true, :all => true})
    archive_manager.compress(LogStash::Environment::CACHE_PATH, target_file)
    FileUtils.rm_rf(LogStash::Environment::CACHE_PATH) if clean?

    puts("Generated at #{target_file}")
  end

  private

  def delete_target_file?
    return true if overwrite?
    puts("File #{target_file} exist, do you want to overwrite it? (Y/N)")
    ("y" == STDIN.gets.strip.downcase ? true : false)
  end

  def validate_target_file
    if File.exist?(target_file)
      if  delete_target_file?
        File.delete(target_file)
      else
        signal_error("Package creation cancelled, a previously generated package exist at location: #{target_file}, move this file to safe place and run the command again")
      end
    end
  end

  def target_file
    target_file = File.join(LogStash::Environment::LOGSTASH_HOME, "plugins_package")
    "#{target_file}#{file_extension}"
  end
end
