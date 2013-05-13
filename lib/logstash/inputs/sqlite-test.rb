require "rubygems"
require "sequel"
require "jdbc/sqlite3" 

    public
    def init_placeholder_table(db)
      begin
        db.create_table :since_table do 
          String :table
          Int    :place
        end
      rescue
        p 'since tables already exists'
      end
    end

    public 
    def init_placeholder(db, table)
      p "init placeholder for #{table}"
      since = db[:since_table]
      since.insert(:table => table, :place => 1)
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
        p "placeholder already exists"
        return x[:place][:place]
      end
    end

    public
    def update_placeholder(db, table, place)
      since = db[:since_table]
      since.insert(:table => table, :place => place)
    end
      
    public 
    def get_all_tables(db)
      tables = db["SELECT * FROM sqlite_master WHERE type = 'table'"].map {|table| table[:name]}
      tables.delete_if { |table| table == 'since_table' }
      return tables
    end
    
    public
    def get_n_rows_from_table(db, table, offset, limit)
      return db["SELECT * FROM #{table} WHERE ('id' > #{offset}) ORDER BY 'id' LIMIT #{limit}"].map { |row| row }
    end
      
    @DB = Sequel.connect("jdbc:sqlite:/home/ec2-user/u2/log/log.db") 

    tables = get_all_tables(@DB)

    #init table stuff
    tables.each{ |table|
      init_placeholder_table(@DB)
      last_place = get_placeholder(@DB, table)
      puts table
      #puts last_place
    }

    #looped tabled stuff
    tables.each{ |table|
      offset = 10
      limit = 5
      #puts get_n_rows_from_table(@DB, table, offset, limit)
      #update_placeholder(@DB, table, offset+limit)
    }

