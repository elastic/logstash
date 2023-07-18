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

module LogStash
  class PipelineState
    attr_reader :pipeline_id

    def initialize(pipeline_id, pipeline)
      @pipeline_id = pipeline_id
      @pipeline = pipeline
      @loading = Concurrent::AtomicBoolean.new(false)

      # this class uses a reentrant lock to ensure thread safe visibility.
      @lock = Monitor.new
    end

    def terminated?
      @lock.synchronize do
        # a loading pipeline is never considered terminated
        @loading.false? && @pipeline.finished_execution?
      end
    end

    def running?
      @lock.synchronize do
        # not terminated and not loading
        @loading.false? && !@pipeline.finished_execution?
      end
    end

    def loading?
      @lock.synchronize do
        @loading.true?
      end
    end

    def set_loading(is_loading)
      @lock.synchronize do
        @loading.value = is_loading
      end
    end

    def set_pipeline(pipeline)
      @lock.synchronize do
        raise(ArgumentError, "invalid nil pipeline") if pipeline.nil?
        @pipeline = pipeline
      end
    end

    def synchronize
      @lock.synchronize do
        yield self
      end
    end

    def pipeline
      @lock.synchronize { @pipeline }
    end
  end

  class PipelineStates

    def initialize
      @states = {}
      @locks = {}
      @lock = Mutex.new
    end

    def get(pipeline_id)
      @lock.synchronize do
        @states[pipeline_id]
      end
    end

    def put(pipeline_id, state)
      @lock.synchronize do
        @states[pipeline_id] = state
      end
    end

    def remove(pipeline_id)
      @lock.synchronize do
        @states.delete(pipeline_id)
      end
    end

    def size
      @lock.synchronize do
        @states.size
      end
    end

    def empty?
      @lock.synchronize do
        @states.empty?
      end
    end

    def each_with_object(init, &block)
      states = @lock.synchronize { @states.dup }
      states.each_with_object(init, &block)
    end

    def get_lock(pipeline_id)
      @lock.synchronize do
        @locks[pipeline_id] ||= Mutex.new
      end
    end
  end

  class PipelinesRegistry
    attr_reader :states

    include LogStash::Util::Loggable

    def initialize
      @states = PipelineStates.new
    end

    # Execute the passed creation logic block and create a new state upon success
    # @param pipeline_id [String, Symbol] the pipeline id
    # @param pipeline [Pipeline] the new pipeline to create
    # @param create_block [Block] the creation execution logic
    #
    # @yieldreturn [Boolean] the new pipeline creation success
    #
    # @return [Boolean] new pipeline creation success
    def create_pipeline(pipeline_id, pipeline, &create_block)
      lock = @states.get_lock(pipeline_id)
      lock.lock
      success = false

      state = @states.get(pipeline_id)

      if state && !state.terminated?
        logger.error("Attempted to create a pipeline that already exists", :pipeline_id => pipeline_id)
        return false
      end

      if state.nil?
        state = PipelineState.new(pipeline_id, pipeline)
        state.set_loading(true)
        @states.put(pipeline_id, state)
        begin
          success = yield
        ensure
          state.set_loading(false)
          @states.remove(pipeline_id) unless success
        end
      else
        state.set_loading(true)
        state.set_pipeline(pipeline)
        begin
          success = yield
        ensure
          state.set_loading(false)
        end
      end

      success
    ensure
      lock.unlock
    end

    # Execute the passed termination logic block
    # @param pipeline_id [String, Symbol] the pipeline id
    # @param stop_block [Block] the termination execution logic
    #
    # @yieldparam [Pipeline] the pipeline to terminate
    def terminate_pipeline(pipeline_id, &stop_block)
      lock = @states.get_lock(pipeline_id)
      lock.lock

      state = @states.get(pipeline_id)
      if state.nil?
        logger.error("Attempted to terminate a pipeline that does not exists", :pipeline_id => pipeline_id)
      else
        yield(state.pipeline)
      end
    ensure
      lock.unlock
    end

    # Execute the passed reloading logic block in the context of the loading state and set new pipeline in state
    # @param pipeline_id [String, Symbol] the pipeline id
    # @param reload_block [Block] the reloading execution logic
    #
    # @yieldreturn [Array<Boolean, Pipeline>] the new pipeline creation success and new pipeline object
    #
    # @return [Boolean] new pipeline creation success
    def reload_pipeline(pipeline_id, &reload_block)
      lock = @states.get_lock(pipeline_id)
      lock.lock
      success = false

      state = @states.get(pipeline_id)

      if state.nil?
        logger.error("Attempted to reload a pipeline that does not exists", :pipeline_id => pipeline_id)
        return false
      end

      state.set_loading(true)
      begin
        success, new_pipeline = yield
        state.set_pipeline(new_pipeline)
      ensure
        state.set_loading(false)
      end

      success
    ensure
      lock.unlock
    end

    # Delete the pipeline that is terminated
    # @param pipeline_id [String, Symbol] the pipeline id
    # @return [Boolean] pipeline delete success
    def delete_pipeline(pipeline_id)
      lock = @states.get_lock(pipeline_id)
      lock.lock

      state = @states.get(pipeline_id)

      if state.nil?
        logger.error("Attempted to delete a pipeline that does not exists", :pipeline_id => pipeline_id)
        return false
      end

      if state.terminated?
        @states.remove(pipeline_id)
        logger.info("Removed pipeline from registry successfully", :pipeline_id => pipeline_id)
        return true
      else
        logger.info("Attempted to delete a pipeline that is not terminated", :pipeline_id => pipeline_id)
        return false
      end
    ensure
      lock.unlock
    end

    # @param pipeline_id [String, Symbol] the pipeline id
    # @return [Pipeline] the pipeline object or nil if none for pipeline_id
    def get_pipeline(pipeline_id)
      state = @states.get(pipeline_id.to_sym)
      state.nil? ? nil : state.pipeline
    end

    # @return [Fixnum] number of items in the states collection
    def size
      @states.size
    end

    # @return [Boolean] true if the states collection is empty.
    def empty?
      @states.empty?
    end

    # @return [Hash{String=>Pipeline}]
    def running_pipelines(include_loading: false)
      select_pipelines { |state| state.running? || (include_loading && state.loading?) }
    end

    def loading_pipelines
      select_pipelines { |state| state.loading? }
    end

    def loaded_pipelines
      select_pipelines { |state| !state.loading? }
    end

    # @return [Hash{String=>Pipeline}]
    def non_running_pipelines
      select_pipelines { |state| state.terminated? }
    end

    # @return [Hash{String=>Pipeline}]
    def running_user_defined_pipelines
      select_pipelines { |state| !state.terminated? && !state.pipeline.system? }
    end

    private

    # Returns a mapping of pipelines by their ids.
    # Pipelines can optionally be filtered by their `PipelineState` by passing
    # a block that returns truthy when a pipeline should be included in the
    # result.
    #
    # @yieldparam [PipelineState]
    # @yieldreturn [Boolean]
    #
    # @return [Hash{String=>Pipeline}]
    def select_pipelines(&optional_state_filter)
      @states.each_with_object({}) do |(id, state), memo|
        if state && (!block_given? || state.synchronize(&optional_state_filter))
          memo[id] = state.pipeline
        end
      end
    end
  end
end
