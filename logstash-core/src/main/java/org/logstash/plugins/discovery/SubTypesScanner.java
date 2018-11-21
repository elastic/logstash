package org.logstash.plugins.discovery;

import java.util.List;

/** scans for superclass and interfaces of a class, allowing a reverse lookup for subtypes */
public class SubTypesScanner extends AbstractScanner {

    /** created new SubTypesScanner. will exclude direct Object subtypes */
    public SubTypesScanner() {
        this(true); //exclude direct Object subtypes by default
    }

    /** created new SubTypesScanner.
     * @param excludeObjectClass if false, include direct {@link Object} subtypes in results.  */
    public SubTypesScanner(boolean excludeObjectClass) {
        if (excludeObjectClass) {
            filterResultsBy(new FilterBuilder().exclude(Object.class.getName())); //exclude direct Object subtypes
        }
    }

    @SuppressWarnings({"unchecked"})
    public void scan(final Object cls) {
        String className = getMetadataAdapter().getClassName(cls);
        String superclass = getMetadataAdapter().getSuperclassName(cls);

        if (acceptResult(superclass)) {
            getStore().put(superclass, className);
        }

        for (String anInterface : (List<String>) getMetadataAdapter().getInterfacesNames(cls)) {
            if (acceptResult(anInterface)) {
                getStore().put(anInterface, className);
            }
        }
    }
}
