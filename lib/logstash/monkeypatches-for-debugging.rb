if $DEBUGLIST.include?("require")
  module Kernel
    alias_method :require_debug, :require

    def require(path)
      result = require_debug(path)
      puts "require(\"#{path}\") => #{result} (from: #{caller[1]})"
    end

    alias_method :load_debug, :load

    def load(path)
      puts "load(\"#{path}\")"
      return load_debug(path)
    end
  end
end
