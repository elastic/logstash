package org.logstash.health;

import com.google.common.collect.Iterables;

import java.util.EnumSet;

public class HealthObserver {
    public final Status getStatus() {
        // INTERNAL-ONLY Proof-of-concept to show flow-through to API results
        switch (System.getProperty("logstash.apiStatus", "green")) {
            case "green":  return Status.GREEN;
            case "yellow": return Status.YELLOW;
            case "red":    return Status.RED;
            case "random":
                final EnumSet<Status> statuses = EnumSet.allOf(Status.class);
                return Iterables.get(statuses, new java.util.Random().nextInt(statuses.size()));
            default:
                return Status.UNKNOWN;
        }
    }
}
