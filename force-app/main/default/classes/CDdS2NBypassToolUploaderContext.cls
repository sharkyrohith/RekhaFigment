/**
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			22 / 12 / 2020
 * @description		On an bypass tool upldoad, this class holds the state of the process.
*/
public with sharing class CDdS2NBypassToolUploaderContext {
    public static final String PARTITION_PREFIX = 'local.DoorDash.S2NBypassToolUploaderCtx';
    @AuraEnabled public CDdS2NBypassToolUploaderCSV csv { get; set; }
    @AuraEnabled public List<Map<String, Object>> dataTable = new List<Map<String, Object>>();
    @AuraEnabled public List<String> batchErrors = new List<String>();
    public String csvRaw { get; set; }
    public String filename { get; set; }
    public String reason { get; set; }
    public Boolean overwrite { get; set; }
    public Id userId { get; set; }
    public String msSyncStageStr { get; set; }
    public Boolean isImportable { get; set; }
    @AuraEnabled public String batchId { get; set; }
    @AuraEnabled public List<String> columns = new List<String>();
    
    @TestVisible
    private CDdS2NBypassToolUploaderContext() {
        this.userId = UserInfo.getUserId();
    }
    
    public CDdS2NBypassToolUploaderContext(String csvRaw, String userId, String msSyncStage, String reason, Boolean overwrite, String filename) {
        this();
        this.csvRaw = csvRaw;
        this.reason = reason;
        this.msSyncStageStr =  msSyncStage;
        this.userId = userId;
        this.filename = filename;
        this.isImportable = false;
        this.overwrite = overwrite;
    }

    public String partitionKey() {
        return PARTITION_PREFIX + this.userId;
    }
}