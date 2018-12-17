package org.logstash.plugins.discovery;

import java.lang.annotation.Inherited;
import java.util.List;

/**
 * scans for class's annotations, where @Retention(RetentionPolicy.RUNTIME)
 */
@SuppressWarnings("unchecked")
public class TypeAnnotationsScanner extends AbstractScanner {

    @Override
    public void scan(final Object cls) {
        final String className = getMetadataAdapter().getClassName(cls);

        for (String annotationType : (List<String>) getMetadataAdapter().getClassAnnotationNames(cls)) {

            if (acceptResult(annotationType) ||
                annotationType.equals(Inherited.class.getName())) { //as an exception, accept Inherited as well
                getStore().put(annotationType, className);
            }
        }
    }

}

