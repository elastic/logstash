
require 'rubygems'
require 'lib/net/message'
require 'lib/net/socketmux'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/ping'

require 'ferret'
require 'lib/log/text'
require 'config'


module LogStash; module Net; module Servers
  class Indexer < LogStash::Net::MessageSocketMux
    def initialize(addr="0.0.0.0", port=3001)
      # 'super' is not the same as 'super()', and we want super().
      super()
      listen(addr, port)
      @indexes = Hash.new
      @lines = Hash.new
    end

    def IndexEventRequestHandler(request)
      response = LogStash::Net::Messages::IndexEventResponse.new
      response.id = request.id

      log_type = request.log_type
      entry = $logs[log_type].parse_entry(request.log_data)
      if !entry
        response.code = 1
        response.error = "Entry was #{entry.inspect}"
      else
        response.code = 0
        if not @indexes.member?(log_type)
          if not File.exists?($logs[log_type].index_dir)
            field_infos = Index::FieldInfos.new(:store => :no,
                                                :term_vector => :no)
            field_infos.add_field(:@LINE,
                                  :store => :compressed,
                                  :index => :no)
            [:@DATE, :@LOG_TYPE, :@SOURCE_HOST].each do |special|
              field_infos.add_field(special,
                                    :store => :compressed,
                                    :index => :untokenized)
            end
            field_infos.create_index($logs[log_type].index_dir)
          end
          @indexes[log_type] = Index::Index.new(:path => $logs[log_type].index_dir)
        end

        entry["@LOG_TYPE"] = log_type
        @indexes[log_type] << entry

        @lines[log_type] += 1
        if @lines[log_type] % 100 == 0
          puts "COMMIT INDEX"
          @indexes[log_type].commit
        end

      end
      return response
    end

    def PingRequestHandler(request)
      response = LogStash::Net::Messages::PingResponse.new
      response.id = request.id
      response.pingdata = request.pingdata
      return response
    end

  end # Indexer
end; end; end # LogStash::Net::Server
