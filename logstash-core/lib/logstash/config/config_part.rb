# encoding: utf-8

module LogStash module Config
 class ConfigPart
   attr_reader :source_loader, :pipeline_name, :metadata, :config_string

   def initialize(source_loader, pipeline_name, metadata, config_string)
     @source_loader = source_loader
     @pipeline_name = pipeline_name
     @metadata = metadata
     @config_string = config_string
   end

   def inspect
     "#{source_loader} => from: #{metadata} pipeline_name: #{pipeline_name}"
   end
 end
end end
