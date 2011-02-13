require "sinatra/base"

module Sinatra
  module RequireParam
    def require_param(*fields)
      missing = []
      fields.each do |field|
        if params[field].nil?
          missing << field
        end
      end
      return missing
    end # def require_param
  end # module RequireParam

  helpers RequireParam
end # module Sinatra
