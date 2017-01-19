# encoding: utf-8
module LogStash module Config module Source
  class Base
    def pipeline_configs
      raise NotImplementedError, "`#pipeline_configs` must be implemented!"
    end

    def self.match?(settings)
      raise NotImplementedError, "`.match?` must be implemented!"
    end
  end
end end end
