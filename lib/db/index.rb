require 'rubygems' if __FILE__ == $0
require 'tokyocabinet'
require 'ap'

module LogStash; module DB;
  class Index
    def initialize(path)
      @tdb = TokyoCabinet::TDB::new
      @path = path
      open_db
    end # def initialize

    private
    def open_db
      ret = @tdb.open(@path, TokyoCabinet::TDB::OWRITER \
                      | TokyoCabinet::TDB::OCREAT | TokyoCabinet::TDB::ONOLCK)
      @tdb.setindex("@DATE", TokyoCabinet::TDB::ITDECIMAL)
      if !ret
        ecode = @tdb.ecode
        STDERR.puts("open error: #{@tdb.errmsg(ecode)}")
      end
    end

    public
    def index(data)
      key = @tdb.genuid
      ret = @tdb.put(key, data)
      if !ret
        ecode = @tdb.ecode
        STDERR.puts("open error: #{@tdb.errmsg(ecode)}")
      end
    end

    public
    def close
      @tdb.close
    end

    public
    def addindex(column, type)
      case type
      when "string"
        @tdb.setindex(column, TokyoCabinet::TDB::ITTOKEN)
        #@tdb.setindex(column, TokyoCabinet::TDB::ITLEXICAL)
      else
        STDERR.puts("Invalid index type: #{type}")
      end
    end
  end # class Index
end; end # module LogStash::DB

if __FILE__ == $0
  i = LogStash::DB::Index.new(ARGV[0])
  args = ARGV[1..-1]
  args.each do |arg|
    key, val = arg.split(":", 2)
    i.addindex(key, val)
  end
  i.close
end
