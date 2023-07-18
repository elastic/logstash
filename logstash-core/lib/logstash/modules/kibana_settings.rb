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

require_relative "kibana_base"

module LogStash module Modules class KibanaSettings < KibanaBase
  include LogStash::Util::Loggable

  class Setting
    attr_reader :name, :value

    def initialize(name, value)
      @name, @value = name, value
    end
  end

  attr_reader :import_path, :content

  # content is an array of Setting required for this module
  def initialize(import_path, content)
    @import_path, @content = import_path, content
  end

  def import(client)
    # e.g. curl "http://localhost:5601/api/kibana/settings"
    # 6.0.0-beta1 -> {"settings":{"buildNum":{"userValue":15613},"defaultIndex":{"userValue":"arcsight-*"}}}
    # 5.4 -> {"settings":{"defaultIndex":{"userValue":"cef-*"},"metrics:max_buckets":{"userValue":"600000"}}}
    # array of Setting objects
    # The POST api body { "changes": { "defaultIndex": "arcsight-*", "metrics:max_buckets": "400" } }
    settings = {}
    content.each do |setting|
      settings[setting.name] = "#{setting.value}"
    end
    body = {"changes" => settings}
    response = client.post(import_path, body)
    if response.failed?
      logger.error("Attempted POST failed", :url_path => import_path, :response => response.body)
    end
    response
  end
end end end
