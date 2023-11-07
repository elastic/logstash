# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'util'

module LogStash module GeoipDatabaseManagement
  class Metric
    include GeoipDatabaseManagement::Util

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

    def initialize_metrics(metadatas)
      metadatas.each do |row|
        type = row[Metadata::Column::DATABASE_TYPE]
        @metric.namespace([:database, type.to_sym]).tap do |n|
          n.gauge(:status, DATABASE_INIT)
          n.gauge(:last_updated_at, unix_time_to_iso8601(row[Metadata::Column::CHECK_AT]))
          n.gauge(:fail_check_in_days, time_diff_in_days(row[Metadata::Column::CHECK_AT]))
        end
      end

      @metric.namespace([:download_stats]).tap do |n|
        check_at = metadatas.map { |row| row[Metadata::Column::CHECK_AT].to_i }.max
        n.gauge(:last_checked_at, unix_time_to_iso8601(check_at))
      end
    end

    def update_download_stats(is_success)
      @metric.namespace([:download_stats]).tap do |n|
        n.gauge(:last_checked_at, Time.now.iso8601)

        if is_success
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
        n.gauge(:last_updated_at, unix_time_to_iso8601(metadata[Metadata::Column::CHECK_AT]))
        n.gauge(:fail_check_in_days, days_without_update)
      end
    end
  end
end end