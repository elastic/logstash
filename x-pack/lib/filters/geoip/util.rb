# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "digest"
require "date"
require "time"

module LogStash module Filters
  module Geoip
    GZ_EXT = 'tgz'.freeze
    DB_EXT = 'mmdb'.freeze
    GEOLITE = 'GeoLite2-'.freeze
    CITY = "City".freeze
    ASN = "ASN".freeze
    DB_TYPES = [ASN, CITY].freeze
    CITY_DB_NAME = "#{GEOLITE}#{CITY}.#{DB_EXT}".freeze
    ASN_DB_NAME = "#{GEOLITE}#{ASN}.#{DB_EXT}".freeze
    DEFAULT_DB_NAMES = [CITY_DB_NAME, ASN_DB_NAME].freeze
    CC = "CC".freeze

    module Util
      def get_db_path(database_type, dirname)
        ::File.join(get_data_dir_path, dirname, "#{GEOLITE}#{database_type}.#{DB_EXT}")
      end

      def get_gz_path(database_type, dirname)
        ::File.join(get_data_dir_path, dirname, "#{GEOLITE}#{database_type}.#{GZ_EXT}")
      end

      def get_dir_path(dirname)
        ::File.join(get_data_dir_path, dirname)
      end

      def get_data_dir_path
        ::File.join(LogStash::SETTINGS.get_value("path.data"), "plugins", "filters", "geoip")
      end

      def file_exist?(path)
        !path.nil? && ::File.exist?(path) && !::File.empty?(path)
      end

      def md5(file_path)
        file_exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)): ""
      end

      def error_details(e, logger)
        error_details = { :cause => e.cause }
        error_details[:backtrace] = e.backtrace if logger.debug?
        error_details
      end

      def time_diff_in_days(timestamp)
        (::Date.today - ::Time.at(timestamp.to_i).to_date).to_i
      end

      def unix_time_to_iso8601(timestamp)
        Time.at(timestamp.to_i).iso8601
      end
    end
  end
end end