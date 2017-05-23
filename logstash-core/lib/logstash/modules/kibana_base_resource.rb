# encoding: utf-8
require "logstash/namespace"
require_relative "resource_base"

module LogStash module Modules class KibanaBaseResource
  include ResourceBase
  def import_path
    base
  end
end end end
