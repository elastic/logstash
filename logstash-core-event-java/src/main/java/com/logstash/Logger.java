package com.logstash;

// minimalist Logger interface to wire a logger callback in the Event class
// for now only warn is defined because this is the only method that's required
// in the Event class.
// TODO: (colin) generalize this

public interface Logger {

    // TODO: (colin) complete interface beyond warn when needed

    void warn(String message);
}
