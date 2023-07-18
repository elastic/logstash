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

module LogStash module Modules class ElasticsearchImporter
  include LogStash::Util::Loggable

  def initialize(client)
    @client = client
  end

  def put(resource, overwrite = true)
    path = resource.import_path
    logger.debug("Attempting PUT", :url_path => path, :file_path => resource.content_path)
    if !overwrite && content_exists?(path)
      logger.debug("Found existing Elasticsearch resource.", :resource => path)
      return
    end
    put_overwrite(path, resource.content)
  end

  private

  def put_overwrite(path, content)
    if content_exists?(path)
      response = @client.delete(path)
    end
    # hmmm, versioning?
    @client.put(path, content).status == 201
  end

  def content_exists?(path)
    response = @client.head(path)
    response.status >= 200 && response.status < 300
  end
end end end # class LogStash::Modules::Importer
