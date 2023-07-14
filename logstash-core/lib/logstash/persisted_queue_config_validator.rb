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

java_import 'org.logstash.common.FsUtil'
java_import 'java.nio.file.Paths'
java_import "java.nio.file.FileStore"
java_import "java.nio.file.Files"

module LogStash
  class PersistedQueueConfigValidator
    include LogStash::Util::Loggable

    def initialize
      @last_check_pipeline_configs = Array.new
      @last_check_pass = false
    end

    # Check the config of persistent queue. Raise BootstrapCheckError if queue.page_capacity > queue.max_bytes
    # Print warning message if fail the space checking
    # @param running_pipelines [Hash pipeline_id (sym) => JavaPipeline]
    # @param pipeline_configs [Array PipelineConfig]
    def check(running_pipelines, pipeline_configs)
      # Compare value of new pipeline config and pipeline registry and cache
      has_update = queue_configs_update?(running_pipelines, pipeline_configs) && cache_check_fail?(pipeline_configs)
      @last_check_pipeline_configs = pipeline_configs
      return unless has_update

      warn_msg = []
      err_msg = []
      queue_path_file_system = Hash.new # (String: queue path, String: file system)
      required_free_bytes  = Hash.new # (String: file system, Integer: size)

      pipeline_configs.select { |config| config.settings.get('queue.type') == 'persisted'}
                      .select { |config| config.settings.get('queue.max_bytes').to_i != 0 }
                      .each do |config|
        max_bytes = config.settings.get("queue.max_bytes").to_i
        page_capacity = config.settings.get("queue.page_capacity").to_i
        pipeline_id = config.settings.get("pipeline.id")
        queue_path = ::File.join(config.settings.get("path.queue"), pipeline_id)
        pq_page_glob = ::File.join(queue_path, "page.*")
        create_dirs(queue_path)
        used_bytes = get_page_size(pq_page_glob)
        file_system = get_file_system(queue_path)

        check_page_capacity(err_msg, pipeline_id, max_bytes, page_capacity)
        check_queue_usage(warn_msg, pipeline_id, max_bytes, used_bytes)

        queue_path_file_system[queue_path] = file_system
        if used_bytes < max_bytes
          required_free_bytes[file_system] = required_free_bytes.fetch(file_system, 0) + max_bytes - used_bytes
        end
      end

      check_disk_space(warn_msg, queue_path_file_system, required_free_bytes)

      @last_check_pass = err_msg.empty? && warn_msg.empty?

      logger.warn(warn_msg.flatten.join(" ")) unless warn_msg.empty?
      raise(LogStash::BootstrapCheckError, err_msg.flatten.join(" ")) unless err_msg.empty?
    end

    def check_page_capacity(err_msg, pipeline_id, max_bytes, page_capacity)
      if page_capacity > max_bytes
        err_msg << "Pipeline #{pipeline_id} 'queue.page_capacity' must be less than or equal to 'queue.max_bytes'."
      end
    end

    def check_queue_usage(warn_msg, pipeline_id, max_bytes, used_bytes)
      if used_bytes > max_bytes
        warn_msg << "Pipeline #{pipeline_id} current queue size (#{used_bytes}) is greater than 'queue.max_bytes' (#{max_bytes})."
      end
    end

    # Check disk has sufficient space for all queues reach their max bytes. Queues may config with different paths/ devices.
    # It uses the filesystem of the path and count the required bytes by filesystem
    def check_disk_space(warn_msg, queue_path_file_system, required_free_bytes)
      disk_warn_msg =
        queue_path_file_system
          .select { |queue_path, file_system| !FsUtil.hasFreeSpace(Paths.get(queue_path), required_free_bytes.fetch(file_system, 0)) }
          .map { |queue_path, file_system| "The persistent queue on path \"#{queue_path}\" won't fit in file system \"#{file_system}\" when full. Please free or allocate #{required_free_bytes.fetch(file_system, 0)} more bytes." }

      warn_msg << disk_warn_msg unless disk_warn_msg.empty?
    end

    def get_file_system(queue_path)
      fs = Files.getFileStore(Paths.get(queue_path))
      fs.name
    end

    # PQ pages size in bytes
    def get_page_size(page_glob)
      ::Dir.glob(page_glob).sum { |f| ::File.size(f) }
    end

    # Compare value in pipeline registry / cache and new pipeline config
    # return true if new pipeline is added or reloadable PQ config has changed
    # @param pipeline_hash [Hash pipeline_id (sym) => JavaPipeline / PipelineConfig]
    # @param new_pipeline_configs [Array PipelineConfig]
    def queue_configs_update?(pipeline_hash, new_pipeline_configs)
      new_pipeline_configs.each do |new_pipeline_config|
        return true unless pipeline_hash.has_key?(new_pipeline_config.pipeline_id.to_sym)

        settings = pipeline_hash.fetch(new_pipeline_config.pipeline_id.to_sym).settings
        return true unless settings.get("queue.type") == new_pipeline_config.settings.get("queue.type") &&
          settings.get("queue.max_bytes") == new_pipeline_config.settings.get("queue.max_bytes") &&
          settings.get("queue.page_capacity") == new_pipeline_config.settings.get("queue.page_capacity") &&
          settings.get("path.queue") == new_pipeline_config.settings.get("path.queue")
      end

      false
    end

    # cache check is to prevent an invalid new pipeline config trigger the check of valid size config repeatedly
    def cache_check_fail?(pipeline_configs)
      last_check_pipeline_configs = @last_check_pipeline_configs.map { |pc| [pc.pipeline_id.to_sym, pc] }.to_h
      queue_configs_update?(last_check_pipeline_configs, pipeline_configs) || !@last_check_pass
    end

    # creates path directories if not exist
    def create_dirs(queue_path)
      path = Paths.get(queue_path)
      # Files.createDirectories raises a FileAlreadyExistsException
      # if pipeline path is a symlink
      return if Files.exists(path)
      Files.createDirectories(path)
    end
  end
end
