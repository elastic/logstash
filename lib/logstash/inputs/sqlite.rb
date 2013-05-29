require "logstash/inputs/base"
require "logstash/namespace"
require "sequel"
require "jdbc/sqlite3" 

class LogStash::Inputs::Sqlite < LogStash::Inputs::Base
    config_name "sqlite"
    plugin_status "experimental"

    config :dbfile, :validate => :string, :required => true
    config :exclude, :validate => :array
    config :stat_interval, :validate => :number, :default => 15

    public
    def init_placeholder_table(db)
      begin
        db.create_table :since_table do 
          String :table
          Int    :place
        end
      rescue
        @logger.debug('since tables already exists')
      end
    end

    public
    def get_placeholder(db, table)
      since = db[:since_table]
      x = since.where(:table => "#{table}")
      p x
      if x[:place].nil?
        p 'place is 0'
        init_placeholder(db, table) 
        return 0
      else
        @logger.debug("placeholder already exists, it is #{x[:place]}")
        return x[:place][:place]
      end
    end

    public 
    def init_placeholder(db, table)
      @logger.debug("init placeholder for #{table}")
      since = db[:since_table]
      since.insert(:table => table, :place => 1)
    end

    public
    def update_placeholder(db, table, place)
      @logger.debug("set placeholder to #{place}")
      since = db[:since_table]
      since.where(:table => table).update(:place => place)
    end

    public 
    def get_all_tables(db)
      tables = db["SELECT * FROM sqlite_master WHERE type = 'table'"].map {|table| table[:name]}
      tables.delete_if { |table| table == 'since_table' }
      return tables
    end
    
    public
    def get_n_rows_from_table(db, table, offset, limit)
      dataset = db["SELECT * FROM #{table}"]
      return db["SELECT * FROM #{table} WHERE (id >= #{offset}) ORDER BY 'id' LIMIT #{limit}"].map { |row| row }
    end
    
    public
    def register
      require "digest/md5"
      LogStash::Util::set_thread_name("input|sqlite|#{dbfile}")
      @logger.info("Registering sqlite input", :database => @dbfile)
      @format = "json_event"
      @DB = Sequel.connect("jdbc:sqlite:#{dbfile}") 
      @tables = get_all_tables(@DB)
      @table_data = Hash.new
      @tables.each{ |table|
        init_placeholder_table(@DB)
        last_place = get_placeholder(@DB, table)
        @table_data[table] = { :name => table, :place => last_place }
      }

    end # def register

    public
    def run(queue)
      begin
        @logger.debug("Tailing sqlite db'#{@dbfile}'")
        loop do
          @table_data.each{ |k, table|
            table_name = table[:name]
            offset = table[:place]
            limit = 5
            @logger.debug("offset is #{offset}")
            lines = get_n_rows_from_table(@DB, table_name, offset, limit)
            lines.each{ |line| 
                line.delete(:id)
                entry = {}
                line.each { |name,element|
                  entry["@#{name}"] = element
                }

                begin
                  e = to_event(JSON.dump(entry), "sqlite://#{@dbfile}")
                rescue EOFError => ex
                  # stdin closed, finish
                  break
                end
                queue << e if e
            }
            update_placeholder(@DB, table_name, offset+limit)
            @table_data[k][:place] = offset+limit
          }
        end # loop
      end # begin/rescue
    end #run

end # class Logtstash::Inputs::EventLog

