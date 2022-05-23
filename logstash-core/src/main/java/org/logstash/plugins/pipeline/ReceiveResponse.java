package org.logstash.plugins.pipeline;

public final class ReceiveResponse {
    private final PipelineInput.ReceiveStatus status;
    private final Integer sequencePosition;
    private final Throwable cause;

    public static ReceiveResponse closing() {
        return new ReceiveResponse(PipelineInput.ReceiveStatus.CLOSING);
    }

    public static ReceiveResponse completed() {
        return new ReceiveResponse(PipelineInput.ReceiveStatus.COMPLETED);
    }

    public static ReceiveResponse failedAt(int sequencePosition, Throwable cause) {
        return new ReceiveResponse(PipelineInput.ReceiveStatus.FAIL, sequencePosition, cause);
    }

    private ReceiveResponse(PipelineInput.ReceiveStatus status) {
        this(status, null);
    }

    private ReceiveResponse(PipelineInput.ReceiveStatus status, Integer sequencePosition) {
        this(status, sequencePosition, null);
    }

    private ReceiveResponse(PipelineInput.ReceiveStatus status, Integer sequencePosition, Throwable cause) {
        this.status = status;
        this.sequencePosition = sequencePosition;
        this.cause = cause;
    }

    public PipelineInput.ReceiveStatus getStatus() {
        return status;
    }

    public Integer getSequencePosition() {
        return sequencePosition;
    }

    public boolean wasSuccess() {
        return status == PipelineInput.ReceiveStatus.COMPLETED;
    }

    public String getCauseMessage() {
        return cause != null ? cause.getMessage() : "UNDEFINED ERROR";
    }
}
