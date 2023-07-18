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

require "logstash/util"

module LogStash::Util
  # Decorators provides common manipulation on the event data.
  module Decorators
    include LogStash::Util::Loggable
    extend self

    # fields is a hash of field => value
    # where both `field` and `value` can use sprintf syntax.
    def add_fields(fields, event, pluginname)
      fields.each do |field, value|
        field = event.sprintf(field)
        value = Array(value)
        value.each do |v|
          v = event.sprintf(v)
          if event.include?(field)
            # note below that the array field needs to be updated then reassigned to the event.
            # this is important because a construct like event[field] << v will not work
            # in the current Java event implementation. see https://github.com/elastic/logstash/issues/4140
            a = Array(event.get(field))
            a << v
            event.set(field, a)
          else
            event.set(field, v)
          end
          self.logger.debug? and self.logger.debug("#{pluginname}: adding value to field", "field" => field, "value" => value)
        end
      end
    end

    # tags is an array of string. sprintf syntax can be used.
    def add_tags(new_tags, event, pluginname)
      return if new_tags.empty?

      tags = Array(event.get("tags")) # note that Array(nil) => []

      new_tags.each do |new_tag|
        new_tag = event.sprintf(new_tag)
        self.logger.debug? and self.logger.debug("#{pluginname}: adding tag", "tag" => new_tag)
        # note below that the tags array field needs to be updated then reassigned to the event.
        # this is important because a construct like event["tags"] << tag will not work
        # in the current Java event implementation. see https://github.com/elastic/logstash/issues/4140
        tags << new_tag  #unless tags.include?(new_tag)
      end

      event.set("tags", tags)
    end
  end # module LogStash::Util::Decorators
end # module LogStash::Util
