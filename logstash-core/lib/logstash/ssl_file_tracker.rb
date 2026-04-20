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

require "digest"
require "set"

module LogStash
  # Tracks SSL-related file paths referenced by pipelines and reports which
  # pipelines have become stale and should be reloaded.
  #
  # Regular files use WatchService notifications plus SHA-256 checksums so we
  # only mark a pipeline stale when file content actually changes.
  #
  # Symlink paths use mtime polling instead of checksums. In Kubernetes-style
  # certificate rotation, the configured path often stays as the same symlink
  # while its target is swapped atomically through ..data links. Polling the
  # target mtime during converge reliably detects that target change without
  # reading and hashing the file on every cycle.
  class SslFileTracker
    include LogStash::Util::Loggable

    # Known SSL file-path config names that may be declared with a non-path. Some plugins (beats) use :array as validate type
    PLUGIN_SSL_PATH_CONFIG_NAMES = %w[
      ssl_certificate
      ssl_key
      ssl_certificate_authorities
      ssl_keystore_path
      ssl_truststore_path
    ].freeze

    # Holds all per-path watch state in one place.
    # stamp:        latest observed stamp. SHA-256 string for :file paths; mtime (Time) for :symlink paths.
    # callback:     the FileChangeCallback registered with FileWatchService. nil for polled paths.
    # pipeline_ids: Set of pipeline_ids referencing this path. The Java watch is removed only when pipeline_ids is empty.
    # file_type:    :file for regular files (WatchService-driven), :symlink for symlinks (mtime on each converge).
    WatchedFile = Struct.new(:stamp, :callback, :pipeline_ids, :file_type)

    def initialize(file_watch_service)
      @file_watch_service = file_watch_service
      # id includes pipeline_id and xpack service, { id => [file_path] }, tracks which paths each id registered
      @id_paths = {}
      # one entry per path, { file_path => WatchedFile(:stamp, :callback, :pipeline_ids, :file_type) }, tracks which ids each path registered
      @path_watched = {}
      # set of registered pipeline IDs
      @pipeline_ids = Set.new
      # IDs that have detected a cert change since last registration
      @stale_ids = Set.new
      @mutex = Mutex.new
    end

    # Registers an id (pipeline or xpack service) with explicit paths.
    # Fully rolls back tracker state for +id+ and re-raises if the underlying
    # FileWatchService register fails, so callers can fail the operation.
    # @param id [Symbol, String]
    # @param paths [Array<String>]
    # @return [void]
    # @raise [java.io.IOException] if FileWatchService cannot watch a path
    def register_paths(id, paths)
      id = id.to_sym
      # Compute stamps before taking the lock so filesystem I/O stays outside the mutex.
      # Symlink paths use mtime; regular files use SHA-256.
      stamps = paths.each_with_object({}) do |p, h|
        h[p] = ::File.symlink?(p) ? compute_mtime(p) : compute_checksum(p)
      end
      new_registrations = {}

      @mutex.synchronize do
        paths.each do |path|
          entry = @path_watched[path]
          if entry.nil?
            if ::File.symlink?(path)
              entry = WatchedFile.new(stamps[path], nil, Set.new, :symlink)
            else
              entry = WatchedFile.new(stamps[path], nil, Set.new, :file)
              cb = build_callback(path)
              entry.callback = cb
              new_registrations[path] = cb
            end
            @path_watched[path] = entry
            logger.info("Registered path", :id => id, :path => path, :type => entry.file_type)
          end
          entry.pipeline_ids.add(id)
        end
        @id_paths[id] = paths
        @stale_ids.delete(id)
      end

      begin
        new_registrations.each do |path, cb|
          @file_watch_service.register(java.nio.file.Paths.get(path), cb)
        end
      rescue java.io.IOException
        deregister(id)
        raise
      end
    end
    private :register_paths

    # Starts watching all SSL file paths for the pipeline. Paths already watched
    # by another pipeline share the same WatchedFile entry and are not re-registered.
    #
    # register() is called before pipeline startup so certificate rotation that
    # happens after registration can be observed and trigger a reload.
    # Propagates java.io.IOException if the underlying FileWatchService cannot
    # watch a path, after rolling back tracker state.
    #
    # @param pipeline [JavaPipeline]
    # @return [void]
    # @raise [java.io.IOException] if FileWatchService cannot watch a path
    def register(pipeline)
      unless pipeline.reloadable?
        logger.debug("Skipping SSL file tracking for non-reloadable pipeline", :pipeline_id => pipeline.pipeline_id)
        return
      end

      pid = pipeline.pipeline_id.to_sym
      register_paths(pid, ssl_file_paths(pipeline))
      @mutex.synchronize { @pipeline_ids.add(pid) }
    end

    # Stops watching SSL file paths for the pipeline. Cancels the WatchKey only
    # when no other pipeline still references the path.
    # @param pipeline_id [Symbol, String]
    # @return [void]
    def deregister(pipeline_id)
      pid = pipeline_id.to_sym
      deregistrations = []

      @mutex.synchronize do
        @pipeline_ids.delete(pid)
        @stale_ids.delete(pid)
        paths = @id_paths.delete(pid)
        return unless paths

        paths.each do |path|
          entry = @path_watched[path]
          next unless entry

          entry.pipeline_ids.delete(pid)
          next unless entry.pipeline_ids.empty?

          @path_watched.delete(path)
          logger.info("Deregistered path", :pipeline_id => pid, :path => path)
          deregistrations << [path, entry.callback] if entry.file_type == :file
        end
      end

      deregistrations.each do |path, cb|
        @file_watch_service.deregister(java.nio.file.Paths.get(path), cb)
      end
    end

    # Refreshes mtime stamps for symlink paths belonging to the given ids.
    # @param ids [Array, Set]
    # @return [void]
    def refresh_symlink_stamps(ids)
      return if ids.empty?
      target_ids = Set.new(Array(ids).map(&:to_sym))

      # Collect unique polled paths only for the ids.
      polled_paths = @mutex.synchronize do
        target_ids.flat_map { |id| @id_paths[id] || [] }
                 .select { |p| @path_watched[p]&.file_type == :symlink }
                 .uniq
      end

      # Stat outside the mutex
      new_stamps = polled_paths.to_h { |p| [p, compute_mtime(p)] }.compact

      # Update mtime stamps and mark affected ids as stale.
      @mutex.synchronize do
        new_stamps.each do |path, new_stamp|
          entry = @path_watched[path]
          next if entry.nil? || entry.stamp == new_stamp
          logger.info("Symlink stamp changed", :path => path, :old_stamp => entry.stamp, :new_stamp => new_stamp)
          entry.stamp = new_stamp
          @stale_ids.merge(entry.pipeline_ids & target_ids)
        end
      end
    end

    # Refreshes symlink stamps for all registered pipelines.
    # @return [void]
    def refresh_pipeline_symlink_stamps
      ids = @mutex.synchronize { @pipeline_ids.dup }
      return if ids.empty?

      refresh_symlink_stamps(ids)
    end

    # Returns pipeline IDs that are currently stale
    # @return [Array<Symbol>]
    def stale_pipeline_ids
      @mutex.synchronize { (@stale_ids & @pipeline_ids).to_a }
    end

    private

    # Returns a FileChangeCallback lambda that recomputes the SHA-256 checksum
    # for a regular file path and marks affected pipelines stale when it changes.
    def build_callback(path)
      ->(event) {
        new_checksum = compute_checksum(path)
        @mutex.synchronize do
          entry = @path_watched[path]
          if entry && entry.stamp != new_checksum
            logger.info("Certificate changed", :path => path, :old_stamp => entry.stamp, :new_stamp => new_checksum)
            entry.stamp = new_checksum
            @stale_ids.merge(entry.pipeline_ids)
          end
        end
      }
    end

    def compute_checksum(path)
      ::Digest::SHA256.file(path).hexdigest
    rescue SystemCallError, IOError
      nil
    end

    def compute_mtime(path)
      ::File.stat(path).mtime
    rescue SystemCallError, IOError
      nil
    end

    # Returns unique SSL file paths declared across all plugins in the pipeline.
    # Tracks config entries whose name starts with "ssl_" and validates as :path,
    # plus explicit allowlisted SSL settings whose values may be arrays.
    # @param pipeline [JavaPipeline]
    # @return [Array<String>]
    def ssl_file_paths(pipeline)
      (pipeline.inputs + pipeline.filters + pipeline.outputs).flat_map do |plugin|
        target = plugin.respond_to?(:ruby_plugin) ? plugin.ruby_plugin : plugin
        next [] if target.nil?
        next [] unless target.class.respond_to?(:get_config)

        target.class.get_config.to_a
              .select { |name, opts| PLUGIN_SSL_PATH_CONFIG_NAMES.include?(name.to_s) || (opts[:validate] == :path && name.to_s.start_with?("ssl_")) }
              # Array() handles config values that may be declared as arrays.
              # expand_path normalizes relative paths so the same file is never tracked twice.
              .flat_map { |name, _| Array(target.instance_variable_get("@#{name}")).map { |p| ::File.expand_path(p) } }
      end.uniq
    end
  end
end
