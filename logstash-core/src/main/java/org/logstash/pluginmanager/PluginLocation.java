package org.logstash.pluginmanager;

public class PluginLocation {
    final String repositoryUrl;
    final String repositoryId;
    final String group;
    final String artifact;

    public PluginLocation(String repositoryUrl, String repositoryId, String group, String artifact) {
        this.repositoryUrl = repositoryUrl;
        this.repositoryId = repositoryId;
        this.group = group;
        this.artifact = artifact;
    }
}
