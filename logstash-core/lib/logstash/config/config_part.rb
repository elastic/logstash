# encoding: utf-8
module LogStash module Config
 class ConfigPart
   attr_reader :reader, :source_id, :config_string

   def initialize(reader, source_id, config_string)
     @reader = reader
     @source_id = source_id
     @config_string = config_string
   end

   def inspect
     "#{reader} => from: #{source_id}"
   end
 end
end end
