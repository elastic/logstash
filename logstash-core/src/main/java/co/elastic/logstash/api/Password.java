package co.elastic.logstash.api;

/**
 * Wraps a password string so that it is not inadvertently printed or logged.
 */
public class Password {

    private String password;

    public Password(String password) {
        this.password = password;
    }

    public String getPassword() {
        return password;
    }

    @Override
    public String toString() {
        return "<password>";
    }
}
