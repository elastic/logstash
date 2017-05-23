# encoding: utf-8
require "logstash/namespace"
require_relative "file_reader"

module LogStash module Modules module ResourceBase
  attr_reader :base, :content_type, :content_path, :content_id

  def initialize(base, content_type, content_path, content = nil)
    @base, @content_type, @content_path = base, content_type, content_path
    @content_id =  ::File.basename(@content_path, ".*")
    @content = content
  end

  def content
    @content || FileReader.read(@content_path)
  end
end end end
