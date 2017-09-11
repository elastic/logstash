import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ext.JrubyEventExtLibrary;

public final class JrubyEventExtService implements BasicLibraryService {
    @Override
    public boolean basicLoad(final Ruby runtime) {
        new JrubyEventExtLibrary().load(runtime, false);
        return true;
    }
}
