package org.logstash.plugins.acknowledge;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import co.elastic.logstash.api.AcknowledgeToken;

public final class AcknowledgeTokenImpl implements AcknowledgeToken {
    private final String pluginId;
    private final String acknowledgeId;
    // private String pluginId;
    // private String acknowledgeId;

    // AcknowledgeTokenImpl(){}

    @JsonCreator
    AcknowledgeTokenImpl(@JsonProperty("pluginId") final String pluginId, @JsonProperty("acknowledgeId") final String acknowledgeId) {
        if (pluginId == null)
            throw new IllegalArgumentException("pluginId cannot be null");
        if (acknowledgeId == null)
            throw new IllegalArgumentException("acknowledgeId cannot be null");
        this.pluginId = pluginId;
        this.acknowledgeId = acknowledgeId;
    }

    @Override
    public String getPluginId() {
        return pluginId;
    }

    // public void setPluginId(String pluginId) {
    //     this.pluginId = pluginId;
    // }

    @Override
    public String getAcknowledgeId() {
        return acknowledgeId;
    }


    // public void setAcknowledgeId(String acknowledgeId) {
    //     this.acknowledgeId = acknowledgeId;
    // }

    @Override
    public boolean equals(final Object o) {
        if (o == this)
            return true;
        if (!(o instanceof AcknowledgeToken))
            return false;
        final AcknowledgeTokenImpl other = (AcknowledgeTokenImpl) o;
        if (!other.canEqual((Object) this))
            return false;
        if (this.getPluginId() == null ? other.getPluginId() != null
                : !this.getPluginId().equals(other.getPluginId()))
            return false;
        if (this.getAcknowledgeId() == null ? other.getAcknowledgeId() != null
                : !this.getAcknowledgeId().equals(other.getAcknowledgeId()))
            return false;
        return true;
    }

    protected boolean canEqual(final Object other) {
        return other instanceof AcknowledgeTokenImpl;
    }

    @Override
    public int hashCode() {
        final int PRIME = 59;
        int result = 1;
        result = (result * PRIME) + (this.pluginId == null ? 43 : this.pluginId.hashCode());
        result = (result * PRIME) + (this.acknowledgeId == null ? 43 : this.acknowledgeId.hashCode());
        return result;
    }
}

