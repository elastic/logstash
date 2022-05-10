package org.logstash.plugins.aliases;

import javax.annotation.Nonnull;

/**
 * A POJO class linked to {@link AliasPlugin} to map AliasRegistry.yml structure.
 */
public class AliasDocumentReplace {

    /**
     * A document entry need to be replaced.
     */
    @Nonnull
    private String replace;

    /**
     * A value where document entry need to be replaced with.
     */
    @Nonnull
    private String with;

    public String getReplace() {
        return this.replace;
    }

    public String getWith() {
        return this.with;
    }
}
