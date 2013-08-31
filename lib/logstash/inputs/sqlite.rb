require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read rows from an sqlite database.
#
# This is most useful in cases where you are logging directly to a table.
# Any tables being watched must have an 'id' column that is monotonically
# increasing.
#
# All tables are read by default except:
# * ones matching 'sqlite_%' - these are internal/adminstrative tables for sqlite
# * 'since_table' - this is used by this plugin to track state.
#
# ## Example
# 
#     % sqlite /tmp/example.db
#     sqlite> CREATE TABLE weblogs (
#         id INTEGER PRIMARY KEY AUTOINCREMENT,
#         ip STRING,
#         request STRING,
#         response INTEGER);
#     sqlite> INSERT INTO weblogs (ip, request, response) 
#         VALUES ("1.2.3.4", "/index.html", 200);
#
# Then with this logstash config:
#
#     input {
#       sqlite {
#         path => "/tmp/example.db"
#         type => weblogs
#       }
#     }
#     output {
#       stdout {
#         debug => true
#       }
#     }
#
# Sample output:
#
#     {
#       "@source"      => "sqlite://sadness/tmp/x.db",
#       "@tags"        => [],
#       "@fields"      => {
#         "ip"       => "1.2.3.4",
#         "request"  => "/index.html",
#         "response" => 200
#       },
#       "@timestamp"   => "2013-05-29T06:16:30.850Z",
#       "@source_host" => "sadness",
#       "@source_path" => "/tmp/x.db",
#       "@message"     => "",
#       "@type"        => "foo"
#     }
#
class LogStash::Inputs::Sqlite < LogStash::Inputs::Base
  config_name "sqlite"
  milestone 1

  # The path to the sqlite database file.
  config :path, :validate => :string, :required => true

  # Any tables to exclude by name.
  # By default all tables are followed.
  config :exclude_tables, :validate => :array, :default => []

  # How many rows to fetch at a time from each SELECT call.
  config :batch, :validate => :number, :default => 5

  SINCE_TABLE = :since_table

  public
  def init_placeholder_table(db)
    begin
      db.create_table SINCE_TABLE do 
        String :table
        Int    :place
      end
    rescue
      @logger.debug("since tables already exists")
    end
  end

  public
  def get_placeholder(db, table)
    since = db[SINCE_TABLE]
    x = since.where(:table => "#{table}")
    if x[:place].nil?
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
    since = db[SINCE_TABLE]
    since.insert(:table => table, :place => 0)
  end

  public
  def update_placeholder(db, table, place)
    @logger.debug("set placeholder to #{place}")
    since = db[SINCE_TABLE]
    since.where(:table => table).update(:place => place)
  end

  public 
  def get_all_tables(db)
    return db["SELECT * FROM sqlite_master WHERE type = 'table' AND tbl_name != '#{SINCE_TABLE}' AND tbl_name NOT LIKE 'sqlite_%'"].map { |t| t[:name] }.select { |n| !@exclude_tables.include?(n) }
  end
  
  public
  def get_n_rows_from_table(db, table, offset, limit)
    dataset = db["SELECT * FROM #{table}"]
    return db["SELECT * FROM #{table} WHERE (id > #{offset}) ORDER BY 'id' LIMIT #{limit}"].map { |row| row }
  end
  
  public
  def register
    require "sequel"
    require "jdbc/sqlite3" 
    @host = Socket.gethostname
    @logger.info("Registering sqlite input", :database => @path)
    @db = Sequel.connect("jdbc:sqlite:#{@path}") 
    @tables = get_all_tables(@db)
    @table_data = {}
    @tables.each do |table|
      init_placeholder_table(@db)
      last_place = get_placeholder(@db, table)
      @table_data[table] = { :name => table, :place => last_place }
    end
  end # def register

  public
  def run(queue)
    sleep_min = 0.01
    sleep_max = 5
    sleeptime = sleep_min

    begin
      @logger.debug("Tailing sqlite db", :path => @path)
      loop do
        count = 0
        @table_data.each do |k, table|
          table_name = table[:name]
          offset = table[:place]
          @logger.debug("offset is #{offset}", :k => k, :table => table_name)
          rows = get_n_rows_from_table(@db, table_name, offset, @batch)
          count += rows.count
          rows.each do |row| 
            event = LogStash::Event.new("host" => @host, "db" => @db)
            # store each column as a field in the event.
            row.each do |column, element|
              next if column == :id
              event[column.to_s] = element
            end
            queue << event
            @table_data[k][:place] = row[:id]
          end
          # Store the last-seen row in the database
          update_placeholder(@db, table_name, @table_data[k][:place])
        end

        if count == 0
          # nothing found in that iteration
          # sleep a bit
          @logger.debug("No new rows. Sleeping.", :time => sleeptime)
          sleeptime = [sleeptime * 2, sleep_max].min
          sleep(sleeptime)
        else
          sleeptime = sleep_min
        end
      end # loop
    end # begin/rescue
  end #run

end # class Logtstash::Inputs::EventLog

