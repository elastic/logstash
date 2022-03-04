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

require_relative "scaffold"

# This module function should be used when gems or
# x-pack defines modules in their folder structures.
module LogStash module Modules module Util
  def self.register_local_modules(path)
    modules_path = ::File.join(path, "modules")
    ::Dir.foreach(modules_path) do |item|
      # Ignore unix relative path ids
      next if item == '.' or item == '..'
      # Ignore non-directories
      next if !::File.directory?(::File.join(modules_path, ::File::Separator, item))
      LogStash::PLUGIN_REGISTRY.add(:modules, item, Scaffold.new(item, ::File.join(modules_path, item, "configuration")))
    end
  end
end end end
