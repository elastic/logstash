# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module GeoipDatabaseManagement

  require_relative 'constants'
  include Constants # TODO: push up

  module Util
    extend self

    def file_exist?(path)
      !path.nil? && ::File.exist?(path) && !::File.empty?(path)
    end

    def md5(file_path)
      file_exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)) : ""
    end

    def error_details(e, logger)
      {}.tap do |error_details|
        error_details[:exception] = e.message
        error_details[:cause] = e.cause if logger.debug? && e.cause
        error_details[:backtrace] = e.backtrace if logger.debug?
      end
    end

    def time_diff_in_days(timestamp)
      (::Date.today - ::Time.at(timestamp.to_i).to_date).to_i
    end

    def unix_time_to_iso8601(timestamp)
      Time.at(timestamp.to_i).iso8601
    end
  end
end end