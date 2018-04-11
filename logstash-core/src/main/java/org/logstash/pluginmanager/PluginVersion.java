package org.logstash.pluginmanager;

public class PluginVersion implements Comparable<PluginVersion>  {
    final int major;
    final int minor;
    final int patch;
    final boolean snapshot;

    public PluginVersion(int major, int minor, int patch, boolean snapshot){
        this.major = major;
        this.minor = minor;
        this.patch = patch;
        this.snapshot = snapshot;
    }

    public PluginVersion(String versionString) {
        // Split it
        String[] split = versionString.split("\\.");
        major = Integer.valueOf(split[0]);
        minor = Integer.valueOf(split[1]);
        patch = Integer.valueOf(split[2]);
        snapshot = false;
    }

    @Override
    public int compareTo(PluginVersion o) {
        int majorDiff =Integer.compare(major, o.major);
        if (majorDiff != 0) return majorDiff;
        int minorDiff = Integer.compare(minor, o.minor);
        if (minorDiff != 0) return minorDiff;

        return Integer.compare(patch, o.patch);
    }

    @Override public String toString() {
        String prefix = String.format("%s.%s.%s", major, minor, patch);
        if (snapshot) {
            return prefix + "-SNAPSHOT";
        } else {
            return prefix;
        }
    }
}
