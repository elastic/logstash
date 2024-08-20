package org.logstash.health;

public interface Indicator<REPORT extends Indicator.Report> {
    REPORT report(ReportContext reportContext);

    default REPORT report() {
        return report(ReportContext.EMPTY);
    }

    interface Report {
        Status status();
    }
}
