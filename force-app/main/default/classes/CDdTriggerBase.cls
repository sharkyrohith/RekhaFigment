/**
 * Created by Jeremy S. Johnson, Perficient, Inc on 4/2/2020.
 */

public abstract class CDdTriggerBase {
    public Boolean isAsyncOk() {
        return !System.isFuture() && !System.isBatch() && !System.isQueueable();
    }
}