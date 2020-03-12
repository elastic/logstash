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

require_relative "elasticsearch_resource"

module LogStash module Modules class ElasticsearchConfig
  attr_reader :index_name

  # We name it `modul` here because `module` has meaning in Ruby.
  def initialize(modul, settings)
    @directory = ::File.join(modul.directory, "elasticsearch")
    @name = modul.module_name
    @settings = settings
    @full_path = ::File.join(@directory, "#{@name}.json")
    @index_name = @settings.fetch("elasticsearch.template_path", "_template")
  end

  def resources
    [ElasticsearchResource.new(@index_name, "not-used", @full_path)]
  end
end end end
