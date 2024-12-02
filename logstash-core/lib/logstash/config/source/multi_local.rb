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

require "logstash/config/source/local"
require "logstash/settings"

module LogStash module Config module Source
  class MultiLocal < Local
    include LogStash::Util::SubstitutionVariables
    include LogStash::Util::Loggable

    REMOVE_COMMENTS_CONFIG_KEYS = %w(config.string)
    CONFIG_LINE_COMMENT = " #"

    def initialize(settings)
      @original_settings = settings
      super(settings)
      @match_warning_done = false
    end

    def pipeline_configs
      yaml_config_without_comments = remove_comments(retrieve_yaml_pipelines)
      pipelines = deep_replace(yaml_config_without_comments)
      pipelines_settings = pipelines.map do |pipeline_settings|
        clone = @original_settings.clone
        clone.merge_pipeline_settings(pipeline_settings)
      end
      detect_duplicate_pipelines(pipelines_settings)
      pipeline_configs = pipelines_settings.map do |pipeline_settings|
        @settings = pipeline_settings
        # this relies on instance variable @settings and the parent class' pipeline_configs
        # method. The alternative is to refactor most of the Local source methods to accept
        # a settings object instead of relying on @settings.
        local_pipeline_configs # create a PipelineConfig object based on @settings
      end.flatten
      @settings = @original_settings
      pipeline_configs
    end

    def match?
      if modules_cli? || modules? || config_string? || config_path?
        return false
      end
      detect_pipelines if !@detect_pipelines_called
      return !(invalid_pipelines_detected?)
    end

    def invalid_pipelines_detected?
      !@detected_marker || @detected_marker.is_a?(Class)
    end

    def config_conflict?
      @conflict_messages.clear
      # are there any auto-reload conflicts?
      if !(modules_cli? || modules? || config_string? || config_path?)
        detect_pipelines if !@detect_pipelines_called
        if @detected_marker.nil?
          @conflict_messages << I18n.t("logstash.runner.config-pipelines-failed-read", :path => pipelines_yaml_location)
        elsif @detected_marker == false
          @conflict_messages << I18n.t("logstash.runner.config-pipelines-empty", :path => pipelines_yaml_location)
        elsif @detected_marker.is_a?(Class)
          @conflict_messages << I18n.t("logstash.runner.config-pipelines-invalid", :invalid_class => @detected_marker, :path => pipelines_yaml_location)
        elsif @detected_marker.kind_of?(ConfigurationError)
          @conflict_messages << @detected_marker.message
        end
      else
        do_warning? && logger.warn("Ignoring the 'pipelines.yml' file because modules or command line options are specified")
      end
      @conflict_messages.any?
    end

    def retrieve_yaml_pipelines
      # by now, either the config_conflict? or the match? should have ruled out any config problems
      # but we don't rely on this, we can still get IO errors or
      result = read_pipelines_from_yaml(pipelines_yaml_location)
      case result
      when Array
        result
      when false
        raise ConfigurationError, I18n.t("logstash.runner.config-pipelines-empty", :path => pipelines_yaml_location)
      else
        raise ConfigurationError, I18n.t("logstash.runner.config-pipelines-invalid", :invalid_class => result.class, :path => pipelines_yaml_location)
      end
    end

    def read_pipelines_from_yaml(yaml_location)
      yaml_contents = ::File.read(yaml_location) rescue fail(ConfigurationError, I18n.t("logstash.runner.config-pipelines-failed-read-with-exception", :path => yaml_location, exception: $!.inspect))
      ::YAML.safe_load(yaml_contents, fallback: false) rescue fail(ConfigurationError, I18n.t("logstash.runner.config-pipelines-failed-parse-with-exception", :path => yaml_location, exception: $!.inspect))
    end

    def pipelines_yaml_location
      ::File.join(@original_settings.get("path.settings"), "pipelines.yml")
    end

    def detect_duplicate_pipelines(pipelines)
      duplicate_ids = pipelines.group_by {|pipeline| pipeline.get("pipeline.id") }.select {|k, v| v.size > 1 }.map {|k, v| k}
      if duplicate_ids.any?
        raise ConfigurationError, I18n.t("logstash.runner.config-pipelines-duplicate-ids", :path => pipelines_yaml_location, duplicate_ids: duplicate_ids.inspect)
      end
    end

    def detect_pipelines
      result = read_pipelines_from_yaml(pipelines_yaml_location)
      if result.is_a?(Array)
        @detected_marker = true
      elsif result.nil?
        @detected_marker = nil
      elsif !result
        @detected_marker = false
      else
        @detected_marker = result.class
      end
    rescue ConfigurationError => cfg_error
      @detected_marker = cfg_error
    ensure
      @detect_pipelines_called = true
    end

    private

    def do_warning?
      if !(done = true && @match_warning_done)
        @match_warning_done = true
      end
      !done
    end

    ESCAPE_CHAR = "\\"

    def remove_comment(config_line = "")
      refined_line = config_line
      comment_indices = []
      comment_idx = -1
      while (comment_idx = config_line.index(CONFIG_LINE_COMMENT, comment_idx + 1)) != nil
        comment_indices << comment_idx
      end

      double_quotes_count = 0
      single_quotes_count = 0
      config_line.chars.each_with_index do |char, i|
        if char == '"' && (config_line[i - ESCAPE_CHAR.length] != ESCAPE_CHAR || (config_line[i - ESCAPE_CHAR.length] == ESCAPE_CHAR && config_line[i - 2 * ESCAPE_CHAR.length] == ESCAPE_CHAR)) && double_quotes_count == 0 && single_quotes_count == 0
          double_quotes_count += 1 unless comment_indices.include?(i)
        elsif char == '"' && (config_line[i - ESCAPE_CHAR.length] != ESCAPE_CHAR || (config_line[i - ESCAPE_CHAR.length] == ESCAPE_CHAR && config_line[i - 2 * ESCAPE_CHAR.length] == ESCAPE_CHAR)) && double_quotes_count == 1 && single_quotes_count == 0
          double_quotes_count -= 1 unless comment_indices.include?(i)
        end

        if char == "'" && (config_line[i - ESCAPE_CHAR.length] != ESCAPE_CHAR || (config_line[i - ESCAPE_CHAR.length] == ESCAPE_CHAR && config_line[i - 2 * ESCAPE_CHAR.length] == ESCAPE_CHAR)) && double_quotes_count == 0 && single_quotes_count == 0
          single_quotes_count += 1 unless comment_indices.include?(i)
        elsif char == "'" && (config_line[i - ESCAPE_CHAR.length] != ESCAPE_CHAR || (config_line[i - ESCAPE_CHAR.length] == ESCAPE_CHAR && config_line[i - 2 * ESCAPE_CHAR.length] == ESCAPE_CHAR)) && double_quotes_count == 0 && single_quotes_count == 1
          single_quotes_count -= 1 unless comment_indices.include?(i)
        end

        if comment_indices.include?(i) && double_quotes_count == 0 && single_quotes_count == 0
          refined_line = config_line[0...i]
          break
        end
      end
      refined_line
    end

    # @param [Object] `yaml_config` the input object
    # @return [Object] Updated object where its key etries which match the `CONFIG_KEYS_TO_WIPE_OUT_COMMENTS` do not contain comments
    def remove_comments(yaml_config)
      case yaml_config
      when Hash
        yaml_config.each do |key, val|
          yaml_config[key.to_s] = remove_comments(val) if REMOVE_COMMENTS_CONFIG_KEYS.include?(key)
        end
      when Array
        yaml_config.map { |val| remove_comments(val) }
      when String
        yaml_config.lines.map do |yaml_config_line |
          refined_config_line = yaml_config_line.strip.start_with?("#") ? "\n" : yaml_config_line
          refined_config_line.include?(CONFIG_LINE_COMMENT) ? remove_comment(refined_config_line) : refined_config_line
        end.join
      else
        yaml_config
      end
    end
  end
end end end
