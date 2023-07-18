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

namespace "modules" do
  def unpacker(src_file, dest_dir)
    puts "Reading #{src_file}"
    array = JSON.parse(IO.read(src_file))

    if !array.is_a?(Array)
      raise "#{src_file} does not contain a JSON array as the first object"
    end

    array.each do |hash|
      values = hash.values_at("_id", "_type", "_source")
      if values.any?(&:nil?)
        puts "#{src_file} contains a JSON object that does not have _id, _type and _source fields"
        next
      end
      id, subfolder, source = values
      filename = "#{id}.json"

      partial_path = ::File.join(dest_dir, subfolder)
      FileUtils.mkdir_p(partial_path)

      full_path = ::File.join(partial_path, filename)
      FileUtils.rm_f(full_path)

      content = JSON.pretty_generate(source) + "\n"
      puts "Writing #{full_path}"
      IO.write(full_path, content)
    end
  end

  def collector(dashboard_dir, module_name)
    file_paths = Dir.glob(::File.join(dashboard_dir, "*.json"))

    filenames = file_paths.map do |file_path|
      filename = File.basename(file_path, ".json")
      next if filename == module_name
      puts "Adding #{filename}"
      filename
    end.compact

    full_path = ::File.join(dashboard_dir, "#{module_name}.json")
    FileUtils.rm_f(full_path)

    content = JSON.pretty_generate(filenames) + "\n"
    puts "Writing #{full_path}"
    IO.write(full_path, content)
  end

  desc "Unpack kibana resources in a JSON array to individual files"
  task "unpack", :src_file, :dest_dir do |task, args|
    unpacker(args[:src_file], args[:dest_dir])
    puts "Done"
  end

  desc "Collect all dashboards filenames into the module dashboard structure e.g. dashboard/cef.json"
  task "make_dashboard_json", :dashboard_dir, :module_name do |task, args|
    collector(args[:dashboard_dir], args[:module_name])
    puts "Done"
  end

  desc "Unpack all kibana resources from a folder of JSON files."
  # from Kibana / saved objects -> export all
  # rake modules:unpack_all[my_module,/User/me/Downloads/my_module,/User/me/workspace/logstash/modules/my_module/6.x/configuration/kibana]
  # Note - you can not currently export index-patterns from the UI, see: https://github.com/elastic/kibana/issues/4288
  # To get the index-pattern, you need to pull from the .kibana index and manually update
  # curl -XGET 'https://<user>:<password>@<es-host>:<es-port>/.kibana/_search?q=type:index-pattern&size=100&pretty' -o idx-patterns.json
  task "unpack_all", :module_name, :kibana_source_dir, :dest_dir do |task, args|
    module_name = args[:module_name]
    kibana_source_dir = args[:kibana_source_dir]
    dest_dir = args[:dest_dir]

    Dir.glob(::File.join(kibana_source_dir, "*.json")).each do |file_path|
      unpacker(file_path, dest_dir)
    end
    dashboard_dir = ::File.join(dest_dir, "dashboard")
    collector(dashboard_dir, module_name)

    puts "Done"
  end
end
