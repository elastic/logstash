require 'rubygems' if __FILE__ == $0
require 'tokyocabinet'
require 'ap'

module LogStash; module DB;
  class IndexReader
    def initialize(path)
      @tdb = TokyoCabinet::TDB::new
      @path = path
      open_db
    end # def initialize

    private
    def open_db
      ret = @tdb.open(@path, TokyoCabinet::TDB::OREADER | TokyoCabinet::TDB::ONOLCK)
      if !ret
        ecode = @tdb.ecode
        STDERR.puts("open error: #{@tdb.errmsg(ecode)}")
      end
    end

    public
    def each
      @tdb.iterinit
      while ((key = @tdb.iternext()) != nil)
        yield key, @tdb.get(key)
      end
    end

    public
    def search(conditions)
      query = TokyoCabinet::TDBQRY.new(@tdb)
      conditions.each do |key, value|
        #query.addcond(key, TokyoCabinet::TDBQRY::QCSTREQ, value)
        query.addcond(key, TokyoCabinet::TDBQRY::QCSTRINC, value)
      end
      query.setorder("@DATE", TDBQRY::QONUMASC);
      results = query.search
      results.each do |key|
        data = @tdb.get(key)
        yield key, data
      end
    end
  end # class LogStash::DB::IndexReader
end; end # module LogStash::DB

if __FILE__ == $0
  i = LogStash::DB::IndexReader.new(ARGV[0])
  qargs = ARGV[1..-1]
  query = {}
  qargs.each do |arg|
    key, val = arg.split(":", 2)
    query[key] = val
  end

  ap query
  i.search(query) do |key, value|
    ap [key, value["@DATE"], value["@LINE"]]
  end
end
