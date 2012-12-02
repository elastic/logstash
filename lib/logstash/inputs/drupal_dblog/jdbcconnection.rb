require "java"
require "rubygems"
require "jdbc/mysql"

java_import "com.mysql.jdbc.Driver"

# A JDBC mysql connection class.
# The interface is compatible with the mysql2 API.
class LogStash::DrupalDblogJavaMysqlConnection

  def initialize(host, username, password, database, port = nil)
    port ||= 3306

    address = "jdbc:mysql://#{host}:#{port}/#{database}"
    @connection = java.sql.DriverManager.getConnection(address, username, password)
  end # def initialize

  def query(sql)
    if sql =~ /select/i
      return select(sql)
    else
      return update(sql)
    end
  end # def query

  def select(sql)
    stmt = @connection.createStatement
    resultSet = stmt.executeQuery(sql)

    meta = resultSet.getMetaData
    column_count = meta.getColumnCount

    rows = []

    while resultSet.next
      res = {}

      (1..column_count).each do |i|
        name = meta.getColumnName(i)
        case meta.getColumnType(i)
        when java.sql.Types::INTEGER
          res[name] = resultSet.getInt(name)
        else
          res[name] = resultSet.getString(name)
        end
      end

      rows << res
    end

    stmt.close
    return rows
  end # def select

  def update(sql)
    stmt = @connection.createStatement
    stmt.execute_update(sql)
    stmt.close
  end # def update

  def close
    @connection.close
  end # def close

end # class LogStash::DrupalDblogJavaMysqlConnection
