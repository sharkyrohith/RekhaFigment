/**
 *
 * @author: Mahesh Chouhan
 * @date: 2022-09
 * @description BASD-36580 class for retrying DML on records using transaction finalizer
 *
 */
public class CDdRetryQueueable implements Queueable, Finalizer {

    public List<SObject> records;
    public String operationType;
    public String sourceInfo;

    public CDdRetryQueueable(List<SObject> records, String operationType, String sourceInfo) {
        this.records = records;
        this.operationType = operationType;
        this.sourceInfo = sourceInfo;
    }

    public void execute(QueueableContext ctx) {
        Finalizer finalizer = new CDdRetryQueueable(records, operationType, sourceInfo);
        System.attachFinalizer(finalizer);

        if(records != null && !records.isEmpty()) {
            switch on operationType {
                when 'INSERT' {
                    insert records;
                }
                when 'UPDATE' {
                    update records;
                }
                when 'UPSERT' {
                    upsert records;
                }
                when 'DELETE' {
                    delete records;
                }
            }
        }
    }

    /**
     * Checks if Queueable job was successful otherwise re-schedule
     *
     * @param ctx FinalizerContext
     */
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() != ParentJobResult.SUCCESS) {
            try {
                if(Test.isRunningTest()) {
                    throw new CDdException();
                }
                else {
                    System.enqueueJob(new CDdRetryQueueable(records, operationType, sourceInfo));   
                }
            } catch (Exception ex) {
                //After 5 retries, log exception
                List<String> recordIds = new List<String>();
                for(Sobject record : records) {
                    recordIds.add(record.Id);
                }
                String ids = String.join(recordIds, ',');
                CDdErrorUtilities.publishException('CDdRetryQueueable', sourceInfo, ids, ctx.getException());
            }
        }
    }
}