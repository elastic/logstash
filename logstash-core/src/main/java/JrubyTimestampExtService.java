import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class JrubyTimestampExtService implements BasicLibraryService {
    @Override
    public boolean basicLoad(final Ruby runtime) {
        new JrubyTimestampExtLibrary().load(runtime, false);
        return true;
    }
}
