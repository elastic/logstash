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

require "bundler"
require "rake"
require "rake/tasklib"
require "fileutils"
require "net/http"
require "paquet/gem"

# This class add new rake methods to a an existing ruby gem,
# these methods allow developers to create a Uber gem, a uber gem is
# a tarball that contains the current gems and one or more of his dependencies.
#
# This Tool will take care of looking at the current dependency tree defined in the Gemspec and the gemfile
# and will traverse all graph and download the gem file into a specified directory.
#
# By default, the tool won't fetch everything and the developer need to declare what gems he want to download.
module Paquet
  class Task < Rake::TaskLib
    def initialize(target_path, cache_path = nil, &block)
      @gem = Gem.new(target_path, cache_path)

      instance_eval(&block)

      namespace :paquet do
        desc "Build a pack with #{@gem.size} gems: #{@gem.gems.join(",")}"
        task :vendor do
          @gem.pack
        end
      end
    end

    def pack(name)
      @gem.add(name)
    end

    def ignore(name)
      @gem.ignore(name)
    end
  end
end
