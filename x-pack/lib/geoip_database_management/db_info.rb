# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module GeoipDatabaseManagement

  ##
  # The DbInfo is the read-only immutable state of a managed database.
  # It is provided by Subscription#value and Subscription#observe
  class DbInfo

    attr_reader :path

    def initialize(path:, pending: false, expired: false)
      @path = path&.dup.freeze
      @pending = pending
      @expired = expired
    end

    def expired?
      @expired
    end

    def pending?
      @pending
    end

    def removed?
      !@pending && @path.nil?
    end

    EXPIRED = DbInfo.new(path: nil, expired: true)
    PENDING = DbInfo.new(path: nil, pending: true)
    REMOVED = DbInfo.new(path: nil, pending: false)
  end
end end