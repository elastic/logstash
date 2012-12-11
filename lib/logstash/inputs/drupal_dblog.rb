require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "php_serialize"

if RUBY_PLATFORM == 'java'
  require "logstash/inputs/drupal_dblog/jdbcconnection"
else
  require "mysql2"
end

# Retrieve watchdog log events from a Drupal installation with DBLog enabled.
# The events are pulled out directly from the database.
# The original events are not deleted, and on every consecutive run only new
# events are pulled.
#
# The last watchdog event id that was processed is stored in the Drupal
# variable table with the name "logstash_last_wid". Delete this variable or
# set it to 0 if you want to re-import all events.
#
# More info on DBLog: http://drupal.org/documentation/modules/dblog
#
class LogStash::Inputs::DrupalDblog < LogStash::Inputs::Base
  config_name "drupal_dblog"
  plugin_status "experimental"

  # Specify all drupal databases that you whish to import from.
  # This can be as many as you whish.
  # The format is a hash, with a unique site name as the key, and a databse
  # url as the value.
  #
  # Example:
  # [
  #   "site1", "mysql://user1:password@host1.com/databasename",
  #   "other_site", "mysql://user2:password@otherhost.com/databasename",
  #   ...
  # ]
  config :databases, :validate => :hash

  # By default, the event only contains the current user id as a field.
  # If you whish to add the username as an additional field, set this to true.
  config :add_usernames, :validate => :boolean, :default => false

  # Time between checks in minutes.
  config :interval, :validate => :number, :default => 10

  # Label this input with a type.
  # Types are used mainly for filter activation.
  #
  #
  # If you create an input with type "foobar", then only filters
  # which also have type "foobar" will act on them.
  #
  # The type is also stored as part of the event itself, so you
  # can also use the type to search for in the web interface.
  config :type, :validate => :string, :default => 'watchdog'

  public
  def initialize(params)
    super
    @format = "json_event"
  end # def initialize

  public
  def register
  end # def register

  public
  def config_init(params)
    super

    dbs = {}
    valid = true

    @databases.each do |name, rawUri|
      uri = URI(rawUri)

      dbs[name] = {
        "site" => name,
        "scheme" => uri.scheme,
        "host" => uri.host,
        "user" => uri.user,
        "password" => uri.password,
        "database" => uri.path.sub('/', ''),
        "port" => uri.port.to_i
      }

      if not (
        uri.scheme and not uri.scheme.empty?\
        and uri.host and not uri.host.empty?\
        and uri.user and not uri.user.empty?\
        and uri.password\
        and uri.path and not uri.path.sub('/', '').empty?
      )
        @logger.error("Drupal DBLog: Invalid database URI for #{name} : #{rawUri}")
        valid = false
      end
      if not uri.scheme == 'mysql'
        @logger.error("Drupal DBLog: Only mysql databases are supported.")
        valid = false
      end
    end

    if not valid
      @logger.error("Config validation failed.")
      exit 1
    end

    @databases = dbs
  end #def config_init

  public
  def run(output_queue)
    @logger.info("Initializing drupal_dblog")

    loop do
      @logger.debug("Drupal DBLog: Starting to fetch new watchdog entries")
      start = Time.now.to_i

      @databases.each do |name, db|
        @logger.debug("Drupal DBLog: Checking database #{name}")
        check_database(output_queue, db)
      end

      timeTaken = Time.now.to_i - start
      @logger.debug("Drupal DBLog: Fetched all new watchdog entries in #{timeTaken} seconds")

      # If fetching of all databases took less time than the interval,
      # sleep a bit.
      sleepTime = @interval * 60 - timeTaken
      if sleepTime > 0
        @logger.debug("Drupal DBLog: Sleeping for #{sleepTime} seconds")
        sleep(sleepTime)
      end
    end # loop
  end # def run

  private
  def initialize_client(db)
    if db["scheme"] == 'mysql'

      if not db["port"] > 0
        db["port"] = 3306
      end

      if RUBY_PLATFORM == 'java'
        @client = LogStash::DrupalDblogJavaMysqlConnection.new(
            db["host"],
            db["user"],
            db["password"],
            db["database"],
            db["port"]
        )
      else
        @client = Mysql2::Client.new(
            :host => db["host"],
            :port => db["port"],
            :username => db["user"],
            :password => db["password"],
            :database => db["database"]
        )
      end
    end
  end #def get_client

  private
  def check_database(output_queue, db)

    begin
      # connect to the MySQL server
      initialize_client(db)

      @sitename = db["site"]

      @usermap = @add_usernames ? get_usermap : nil

      # Retrieve last pulled watchdog entry id
      initialLastWid = get_last_wid
      lastWid = initialLastWid ? initialLastWid : 0

      # Fetch new entries, and create the event
      results = @client.query('SELECT * from watchdog WHERE wid > ' + lastWid.to_s + " ORDER BY wid asc")
      results.each do |row|
        event = build_event(row)
        if event
          output_queue << event
          lastWid = row['wid'].to_s
        end
      end

      set_last_wid(lastWid, initialLastWid == false)
    rescue Exception => e
      @logger.info("Mysql error: ", :error => e.message)
      throw e
    end # begin

    # Close connection
    @client.close
  end # def check_database

  private
  def update_sitename
    if @sitename == ""
      result = @client.query('SELECT value FROM variable WHERE name="site_name"')
      if result.first()
        @sitename = PHP.unserialize(result.first()['value'])
      end
    end
  end # def update_sitename

  private
  def get_last_wid
    result = @client.query('SELECT value FROM variable WHERE name="logstash_last_wid"')
    lastWid = false

    if result.count() > 0
      tmp = result.first()["value"].gsub("i:", "").gsub(";", "")
      lastWid = tmp.to_i.to_s == tmp ? tmp : "0"
    end

    return lastWid
  end # def get_last_wid

  private
  def set_last_wid(wid, insert)
    # Update last import wid variable
    if insert
      # Does not exist yet, so insert
      @client.query('INSERT INTO variable (name, value) VALUES("logstash_last_wid", "' + wid + '")')
    else
      @client.query('UPDATE variable SET value="' + wid + '" WHERE name="logstash_last_wid"')
    end
  end # def set_last_wid

  private
  def get_usermap
    map = {}

    @client.query("SELECT uid, name FROM users").each do |row|
      map[row["uid"]] = row["name"]
    end

    map[0] = "guest"
    return map
  end # def get_usermap

  private
  def build_event(row)
    # Convert unix timestamp
    timestamp = Time.at(row["timestamp"]).to_datetime.iso8601

    msg = row["message"]
    vars = {}

    # Unserialize the variables, and construct the message
    if row['variables'] != 'N;'
      vars = PHP.unserialize(row["variables"])

      if vars.is_a?(Hash)
        vars.each_pair do |k, v|
          if msg.scan(k).length() > 0
            msg = msg.gsub(k.to_s, v.to_s)
          else
            # If not inside the message, add var as an additional field
            row["variable_" + k] = v
          end
        end
      end
    end

    row.delete("message")
    row.delete("variables")
    row.delete("timestamp")

    row["severity"] = row["severity"].to_i

    if @add_usernames and @usermap.has_key?(row["uid"])
      row["user"] = @usermap[row["uid"]]
    end

    entry = {
      "@timestamp" => timestamp,
      "@tags" => [],
      "@type" => "watchdog",
      "@source" => @sitename,
      "@fields" => row,
      "@message" => msg
    }

    event = to_event(JSON.dump(entry), @sitename)

    return event
  end # def build_event

end # class LogStash::Inputs::DrupalDblog
