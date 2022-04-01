package org.logstash.plugins.aliases;

import com.fasterxml.jackson.annotation.JsonProperty;

import javax.annotation.Nonnull;
import javax.annotation.Nullable;
import java.util.List;
import java.util.Map;

/**
 * A POJO class to map AliasRegistry.yml structure.
 */
public class AliasPlugin {

    /**
     * Name of the aliased plugin.
     */
    @Nonnull
    @JsonProperty("alias_name")
    private String aliasName;

    /**
     * The plugin name where aliased plugin maps to.
     */
    @Nonnull
    @JsonProperty("maps_to")
    private String mapsTo;

    /**
     * List of <K,V> entries to replace when transforming artifact to aliased plugin.
     */
    @Nullable
    private List<Map<String, String>> replaces;

    @Nonnull
    public String getAliasName() {
        return aliasName;
    }

    public void setAliasName(@Nonnull String aliasName) {
        this.aliasName = aliasName;
    }

    @Nonnull
    public String getMapsTo() {
        return mapsTo;
    }

    public void setMapsTo(@Nonnull String mapsTo) {
        this.mapsTo = mapsTo;
    }

    @Nullable
    public List<Map<String, String>> getReplaces() {
        return replaces;
    }

    public void setReplaces(@Nullable List<Map<String, String>> replaces) {
        this.replaces = replaces;
    }
}
