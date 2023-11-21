package org.logstash.plugins.aliases;

import com.fasterxml.jackson.annotation.JsonProperty;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import java.util.List;

/**
 * A POJO class to map AliasRegistry.yml structure.
 */
public class AliasPlugin {

    /**
     * Name of the aliased plugin.
     */
    @Nonnull
    private String aliasName;

    /**
     * The plugin name where aliased plugin made from.
     */
    @Nonnull
    private String from;

    public AliasPlugin(String aliasName, String from, List<AliasDocumentReplace> docHeaderReplaces) {
        this.aliasName = aliasName;
        this.from = from;
        this.docHeaderReplaces = docHeaderReplaces;
    }

    /**
     * List of replace entries when transforming artifact doc to aliased plugin doc.
     */
    @Nullable
    private List<AliasDocumentReplace> docHeaderReplaces;

    @Nonnull
    public String getAliasName() {
        return aliasName;
    }

    @Nonnull
    public String getFrom() {
        return from;
    }
}
