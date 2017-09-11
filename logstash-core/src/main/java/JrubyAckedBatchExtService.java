import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;
import org.logstash.ackedqueue.ext.JrubyAckedBatchExtLibrary;

public class JrubyAckedBatchExtService implements BasicLibraryService {
    @Override
    public boolean basicLoad(final Ruby runtime) {
        new JrubyAckedBatchExtLibrary().load(runtime, false);
        return true;
    }
}
