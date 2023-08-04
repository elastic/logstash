# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'util'
require_relative 'constants'

require "csv"

module LogStash module GeoipDatabaseManagement
  class Metadata
    include LogStash::Util::Loggable

    include GeoipDatabaseManagement::Constants
    include GeoipDatabaseManagement::Util

    def initialize(paths)
      @paths = paths
      @metadata_path = paths.resolve("metadata.csv")
    end

    attr_reader :paths

    # csv format: database_type, check_at, gz_md5, dirname, is_eula
    def save_metadata(database_type, dirname, gz_md5:)
      metadata = get_metadata(database_type, false)

      current_timestamp = Time.now.to_i

      entry = []
      entry[Column::DATABASE_TYPE] = database_type
      entry[Column::CHECK_AT] = current_timestamp
      entry[Column::GZ_MD5] = gz_md5
      entry[Column::DIRNAME] = dirname

      metadata << entry
      update(metadata)
    end

    def update_timestamp(database_type)
      update_each_row do |row|
        row[Column::CHECK_AT] = Time.now.to_i if row[Column::DATABASE_TYPE].eql?(database_type)
        row
      end
    end

    def update_each_row(&block)
      metadata = get_all.map do |row|
        yield row
      end
      update(metadata)
    end

    def update(metadata)
      metadata = metadata.sort_by { |row| row[Column::DATABASE_TYPE] }
      ::CSV.open(@metadata_path, 'w') do |csv|
        metadata.each { |row| csv << row }
      end
      logger.trace("metadata updated", :metadata => metadata)
    end

    def touch
      update_each_row(&:itself)
    end

    def unset_path(database_type)
      update_each_row do |row|
        row[Column::DIRNAME] = "" if row[Column::DATABASE_TYPE].eql?(database_type)
        row
      end
    end

    def get_all
      file_exist?(@metadata_path) ? ::CSV.read(@metadata_path, headers: false) : Array.new
    end

    # Give rows of metadata that match/exclude the type
    def get_metadata(database_type, match = true)
      get_all.select { |row| row[Column::DATABASE_TYPE].eql?(database_type) == match }
    end

    # Return a valid database path
    def database_path(database_type)
      get_metadata(database_type).map { |metadata| @paths.db(database_type, metadata[Column::DIRNAME]) }
                                 .reject(&:empty?)
                                 .select { |path| file_exist?(path) }
                                 .last
    end

    def has_type?(database_type)
      get_metadata(database_type).any?
    end

    def gz_md5(database_type)
      get_metadata(database_type).map { |metadata| metadata[Column::GZ_MD5] }
                                 .last || ''
    end

    def check_at(database_type)
      (get_metadata(database_type).map { |metadata| metadata[Column::CHECK_AT] }
                                  .last || 0).to_i
    end

    # Return all active dirname
    def dirnames
      get_all.map { |metadata| metadata[Column::DIRNAME] }.reject(&:empty?)
    end

    def exist?
      file_exist?(@metadata_path)
    end

    def delete
      ::File.delete(@metadata_path) if exist?
    end

    module Column
      DATABASE_TYPE = 0
      CHECK_AT      = 1
      GZ_MD5        = 2
      DIRNAME       = 3
    end
  end
end end