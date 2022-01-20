# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require_relative "database_metadata"
require_relative "download_manager"
require "date"
require "time"

module LogStash module Filters module Geoip class DatabaseMetric
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  DATABASE_INIT = "init".freeze
  DATABASE_UP_TO_DATE = "up_to_date".freeze
  DATABASE_TO_BE_EXPIRED = "to_be_expired".freeze
  DATABASE_EXPIRED = "expired".freeze

  DOWNLOAD_SUCCEEDED = "succeeded".freeze
  DOWNLOAD_FAILED = "failed".freeze
  DOWNLOAD_UPDATING = "updating".freeze

  def initialize(metric)
    # Fallback when testing plugin and no metric collector are correctly configured.
    @metric = metric || LogStash::Instrument::NamespacedNullMetric.new
  end

  def initialize_metrics(metadatas, states)
    metadatas.each do |row|
      type = row[DatabaseMetadata::Column::DATABASE_TYPE]
      @metric.namespace([:database, type.to_sym]).tap do |n|
        n.gauge(:status, states[type].is_eula ? DATABASE_UP_TO_DATE : DATABASE_INIT)
        if states[type].is_eula
          n.gauge(:last_updated_at, unix_time_to_iso8601(row[DatabaseMetadata::Column::DIRNAME]))
          n.gauge(:fail_check_in_days, time_diff_in_days(row[DatabaseMetadata::Column::CHECK_AT]))
        end
      end
    end

    @metric.namespace([:download_stats]).tap do |n|
      check_at = metadatas.map { |row| row[DatabaseMetadata::Column::CHECK_AT].to_i }.max
      n.gauge(:last_checked_at, unix_time_to_iso8601(check_at))
    end
  end

  def update_download_stats(success_cnt)
    @metric.namespace([:download_stats]).tap do |n|
      n.gauge(:last_checked_at, Time.now.iso8601)

      if success_cnt == DB_TYPES.size
        n.increment(:successes, 1)
        n.gauge(:status, DOWNLOAD_SUCCEEDED)
      else
        n.increment(:failures, 1)
        n.gauge(:status, DOWNLOAD_FAILED)
      end
    end
  end

  def set_download_status_updating
    @metric.namespace([:download_stats]).gauge(:status, DOWNLOAD_UPDATING)
  end

  def update_database_status(database_type, database_status, metadata, days_without_update)
    @metric.namespace([:database, database_type.to_sym]).tap do |n|
      n.gauge(:status, database_status)
      n.gauge(:last_updated_at, unix_time_to_iso8601(metadata[DatabaseMetadata::Column::DIRNAME]))
      n.gauge(:fail_check_in_days, days_without_update)
    end
  end

end end end end