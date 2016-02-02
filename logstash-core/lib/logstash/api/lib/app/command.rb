# encoding: utf-8
require "app/service"

module LogStash::Api
  class Command

    attr_reader :service

    def initialize(service = LogStash::Api::Service.instance)
      @service = service
    end

    def run
      raise "Not implemented"
    end

  end
end
