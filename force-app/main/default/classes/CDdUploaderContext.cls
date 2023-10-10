/**
 * Created by Jeremy S. Johnson, Perficient Inc., 1/27/2020.
 *
 * A class for holding context and intermediate calculations across operations and client-server interactions.
 * This includes the user, actionType, raw CSV file, CSV represented as a CDdUploaderCSV object,
 * validations, errors, updateble SObjects, UI data preview as a composite JSON object (Account + Opportunity), etc.
 */

public with sharing class CDdUploaderContext {
    @AuraEnabled public CDdUploaderCSV csv { get; set; }
    @AuraEnabled public List<Map<String, Object>> dataTable = new List<Map<String, Object>>();
    @AuraEnabled public List<String> batchErrors = new List<String>();
    @AuraEnabled public List<String> columns = new List<String>();
    @AuraEnabled public String batchId { get; set; }
    public Boolean enableAtomicUpdates = false;
    public Boolean isCompositeUpdate = false;
    public Boolean isImportable { get; set; }
    public Id userId { get; set; }
    public Integer recordsProcessed = 0;
    public List<SObject> updateListByType = new List<SObject>(); // Object to be updated sorted by SObject type
    public MSSyncStage msSyncStageEnum { get; set; }
    public Map<Id, Map<Id, SObject>> updateListByGroup = new Map<Id, Map<Id, SObject>>(); // Objects to be updated grouped by Account
    public String csvRaw { get; set; }
    public String filename { get; set; }
    public String msSyncStageStr { get; set; }
    public static final String partitionPrefix = 'local.DoorDash.uploaderCtx';

    @TestVisible
    private CDdUploaderContext() {
        this.userId = UserInfo.getUserId();
    }

    public CDdUploaderContext(String csvRaw, String userId, String msSyncStage, String filename) {
        this();
        this.csvRaw = csvRaw;
        this.userId = userId;
        this.msSyncStageStr = msSyncStage;
        this.msSyncStageEnum = CDdS2NUtil.msSyncStageFromString(msSyncStage);
        this.filename = filename;
        this.isImportable = false;
        //this.enableAtomicUpdates = CDdExperimentSvc.getFeatureFlag('Enable_Atomic_Updates__c');
    }

    public String partitionKey() {
        return partitionPrefix + this.userId;
    }

    /**
     * Move csv summary info to uploaderCtx for UI display
     */
    public void finalize() {
        this.isImportable = this.csv.isImportable;
    }
}