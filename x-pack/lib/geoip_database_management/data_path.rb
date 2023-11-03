# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module GeoipDatabaseManagement
  class DataPath
    include GeoipDatabaseManagement::Constants

    def initialize(root)
      @root = ::File::expand_path(root).freeze
    end

    attr_reader :root

    def gz(database_type, dirname)
      resolve(dirname, "#{GEOLITE}#{database_type}.#{GZ_EXT}")
    end

    def db(database_type, dirname)
      resolve(dirname, "#{GEOLITE}#{database_type}.#{DB_EXT}")
    end

    def resolve(relative_path, *more)
      ::File.expand_path(::File.join(relative_path, *more), @root)
    end

  end
end; end