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

module LogStash
  module Rubygems
    extend self

    ##
    # Take a plugin name and get the latest versions available in the gem repository.
    # @param [String] The plugin name
    # @return [Hash] The collection of registered versions
    ##
    def versions(plugin)
      require "gems"
      require_relative "patches/gems"
      Gems.versions(plugin)
    end

    # Take a gem package and extract it to a specific target
    # @param [String] Gem file, this must be a path
    # @param [String, String] Return a Gem::Package and the installed path
    def unpack(file, path)
      require "rubygems/package"
      require "securerandom"

      # We are creating a random directory per extract,
      # if we dont do this bundler will not trigger download of the dependencies.
      # Use case is:
      # - User build his own gem with a fix
      # - User doesnt increment the version
      # - User install the same version but different code or dependencies multiple times..
      basename = ::File.basename(file, '.gem')
      unique = SecureRandom.hex(4)
      target_path = ::File.expand_path(::File.join(path, unique, basename))

      package = ::Gem::Package.new(file)
      package.extract_files(target_path)

      return [package, target_path]
    end
  end
end
