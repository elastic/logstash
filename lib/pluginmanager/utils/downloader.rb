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

require "ruby-progressbar"
require "pluginmanager/utils/http_client"
require "pluginmanager/errors"
require "fileutils"

module LogStash module PluginManager module Utils
  class Downloader
    class ProgressbarFeedback
      FORMAT = "%t [%B] %p%%"
      TITLE = "Downloading"

      attr_reader :progress_bar

      def initialize(max)
        @progress_bar = ProgressBar.create(:title => TITLE,
                                           :starting_at => 0,
                                           :total => max,
                                           :format => FORMAT)
      end

      def update(status)
        progress_bar.progress += status
      end
    end

    class SilentFeedback
      def initialize(max)
      end

      def update(status)
      end
    end

    attr_reader :download_to, :remote_file_uri, :feedback_strategy

    def initialize(remote_file_uri, feedback = SilentFeedback)
      @remote_file_uri = URI(remote_file_uri)
      @download_to = Stud::Temporary.pathname
      @feedback_strategy = feedback
    end

    def fetch(redirect_count = 0)
      # This is defensive programming, but in the real world we do create redirects all the time
      raise HttpClient::RedirectionLimit, "Too many redirection, tried #{REDIRECTION_LIMIT} times" if redirect_count >= HttpClient::REDIRECTION_LIMIT

      begin
        FileUtils.mkdir_p(download_to)
        downloaded_file = ::File.open(::File.join(download_to, ::File.basename(remote_file_uri.path)), "wb")

        HttpClient.start(remote_file_uri) do |http|
          request = Net::HTTP::Get.new(remote_file_uri.path)

          http.request(request) do |response|
            if response.code == "200"
              download_chunks(response, downloaded_file)
            elsif response.code == "302"
              new_uri = response.headers["location"]

              redirect_count += 1
              downloader = self.new(new_uri, feedback_strategy)
              downloader.fetch(redirect_count)
            else
              raise LogStash::PluginManager::FileNotFoundError, "Can't download #{remote_file_uri}" if response.code != "200"
            end
          end
          downloaded_file.close
          downloaded_file.path
        end
      rescue => e
        downloaded_file.close unless downloaded_file.closed?
        FileUtils.rm_rf(download_to)
        raise e
      end
    end

    def self.fetch(remote_file, feedback = SilentFeedback)
      new(remote_file, feedback).fetch
    end

    private
    def download_chunks(response, downloaded_file)
      feedback = feedback_strategy.new(response.content_length)

      response.read_body do |chunk|
        feedback.update(chunk.bytesize)
        downloaded_file.write(chunk)
      end
    end
  end
end end end
