# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module GeoipDatabaseManagement
  module Constants
    GZ_EXT = 'tgz'.freeze
    DB_EXT = 'mmdb'.freeze

    GEOLITE = 'GeoLite2-'.freeze
    CITY = "City".freeze
    ASN = "ASN".freeze
    DB_TYPES = [ASN, CITY].freeze

    CITY_DB_NAME = "#{GEOLITE}#{CITY}.#{DB_EXT}".freeze
    ASN_DB_NAME = "#{GEOLITE}#{ASN}.#{DB_EXT}".freeze
    DEFAULT_DB_NAMES = [CITY_DB_NAME, ASN_DB_NAME].freeze
  end
end end