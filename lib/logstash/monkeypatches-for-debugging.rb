if $DEBUGLIST.include?("require")
  module Kernel
    alias_method :require_debug, :require

    def require(path)
      puts "require(\"#{path}\")"
      return require_debug(path)
    end

    alias_method :load_debug, :load

    def load(path)
      puts "load(\"#{path}\")"
      return load_debug(path)
    end
  end
end
