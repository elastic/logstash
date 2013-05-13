require "logstash/inputs/base"
require "logstash/namespace"

require "sequel"
require "jdbc/sqlite3" 

class LogStash::Inputs::Sqlite < LogStash::Inputs::Base
    config_name "sqlite"
    plugin_status "beta"

    config :dbfile, :validate => :string, :required => true
    config :exclude, :validate => :array
    config :stat_interval, :validate => :number, :default => 15

    public 
    def get_all_tables(db)
      @dataset = db["SELECT *
                        FROM sqlite_master
                        WHERE type = 'table'"]
      return @dataset.first
    end
    
    public
    def register
      require "digest/md5"
      LogStash::Util::set_thread_name("input|sqlite|#{dbfile}")
      @logger.info("Registering sqlite input", :database => @dbfile)
      @logger.debug("connecting to sqlite db'#{@dbfile}'")
      @DB = Sequel.connect("jdbc:sqlite:#{dbfile}") 
      @dataset = @DB["SELECT * FROM log"]
    end # def register

    public
    def run(queue)
      begin
        @logger.debug("Tailing sqlite db'#{@dbfile}'")
        puts get_all_tables(@DB)
        loop do
          event_index = 0
        end # loop
      end # begin/rescue
    end #run

end # class Logtstash::Inputs::EventLog

