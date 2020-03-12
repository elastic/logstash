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

module LogStash; module Util; module ByteValue
  module_function

  B = 1
  KB = B << 10
  MB = B << 20
  GB = B << 30
  TB = B << 40
  PB = B << 50

  def parse(text)
    if !text.is_a?(String)
      raise ArgumentError, "ByteValue::parse takes a String, got a `#{text.class.name}`"
    end
    number = text.to_f
    factor = multiplier(text)

    (number * factor).to_i
  end

  def multiplier(text)
    case text
      when /(?:k|kb)$/
        KB
      when /(?:m|mb)$/
        MB
      when /(?:g|gb)$/
        GB
      when /(?:t|tb)$/
        TB
      when /(?:p|pb)$/
        PB
      when /(?:b)$/
        B
      else
        raise ArgumentError, "Unknown bytes value '#{text}'"
    end
  end

  def human_readable(number)
    value, unit = if number > PB
      [number / PB, "pb"]
    elsif number > TB
      [number / TB, "tb"]
    elsif number > GB
      [number / GB, "gb"]
    elsif number > MB
      [number / MB, "mb"]
    elsif number > KB
      [number / KB, "kb"]
    else
      [number, "b"]
    end

    format("%.2d%s", value, unit)
  end
end end end
