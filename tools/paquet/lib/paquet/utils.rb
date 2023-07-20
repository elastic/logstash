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

require "fileutils"
require "uri"

module Paquet
  class Utils
    HTTPS_SCHEME = "https"
    REDIRECTION_LIMIT = 5

    def self.download_file(source, destination, counter = REDIRECTION_LIMIT)
      raise "Too many redirection" if counter == 0

      begin
        f = File.open(destination, "wb")

        uri = URI.parse(source)

        http = Net::HTTP.new(uri.host, uri.port,)
        http.use_ssl = uri.scheme == HTTPS_SCHEME

        response = http.get(uri.path)

        case response
        when Net::HTTPSuccess
          f.write(response.body)
        when Net::HTTPRedirection
          counter -= 1
          download_file(response['location'], destination, counter)
        else
          raise "Response not handled: #{response.class}, path: #{uri.path}"
        end
        f.path
      rescue => e
        FileUtils.rm_rf(f.path) rescue nil
        raise e
      ensure
        f.close
      end
    end
  end
end
