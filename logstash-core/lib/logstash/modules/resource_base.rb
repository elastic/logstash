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

require "logstash/json"
require_relative "file_reader"

module LogStash module Modules module ResourceBase
  attr_reader :base, :content_type, :content_path, :content_id

  def initialize(base, content_type, content_path, content = nil, content_id = nil)
    @base, @content_type, @content_path = base, content_type, content_path
    @content_id = content_id || ::File.basename(@content_path, ".*")
    # content at this time will be a JSON string
    @content = content
    if !@content.nil?
      @content_as_object = LogStash::Json.load(@content) rescue {}
    end
  end

  def content
    @content ||= FileReader.read(@content_path)
  end

  def to_s
    "#{base}, #{content_type}, #{content_path}, #{content_id}"
  end

  def content_as_object
    @content_as_object ||= FileReader.read_json(@content_path) rescue nil
  end

  def <=>(other)
    to_s <=> other.to_s
  end

  def ==(other)
    to_s == other.to_s
  end
end end end
