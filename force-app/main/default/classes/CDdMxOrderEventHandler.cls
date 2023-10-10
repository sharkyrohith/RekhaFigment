/********************************************************************************************************************
* @author Sriram
* @date 03/22/2022
*
* @group Merchant Services
*
* @description Apex class that handles processing for Merchant Order events         
*
**************************************************************************************************************************************/
public class CDdMxOrderEventHandler {

    private CDdMxOrderEventEnum event;
    private List<Mx_Order_Event__e> mxOrderEvents;
	private List<SObject> sourceObjectData;
    private String sourceSObjectType;
    private List<SObject> sourceSObjects;
    private Set<Id> sourceSObjectIds;
    private String sourceSObjectKeyApiField;
    private Map<Id, SObject> sourceSObjectBySObjectKeyApiFieldValue;

    private String targetSObjectType;
    private List<SObject> targetSObjects;
    private Set<Id> targetSObjectIds;
    private String targetSObjectKeyApiField;
    private Map<Id, SObject> targetSObjectBySObjectKeyApiFieldValue;
    private String targetSObjectDmlOperation;

    /**
     * @description 2 argument default constructor
     * @param CDdMxOrderEventEnum event
     * @param List<Mx_Order_Event__e> mxOrderEvents
     * @return
     */
    public CDdMxOrderEventHandler(CDdMxOrderEventEnum event, List<Mx_Order_Event__e> mxOrderEvents){
        this.event = event;
        this.sourceObjectData = new List<SObject>();
        this.mxOrderEvents = new List<Mx_Order_Event__e>();
        this.mxOrderEvents.addAll(mxOrderEvents);
        this.setVariables();
        this.processForSourceSObjects();
        this.processForTargetSObjects();
    }
    
     /**
     * @description 2 argument default constructor
     * @param CDdMxOrderEventEnum event
     * @param List<Mx_Order_Event__e> mxOrderEvents
     * @return
     */
    public CDdMxOrderEventHandler(CDdMxOrderEventEnum event, List<SObject> sourceObjectData){
        this.event = event;
        this.sourceObjectData = new List<SObject>();
        this.sourceObjectData.addAll(sourceObjectData);
        this.setVariables();
        this.processForSourceSObjects();
        this.processForTargetSObjects();
    }
    
    /**
     * @description Set the instance variables
     * @param
     * @return
     */
    private void setVariables(){
        // Prepare Source SObject variables 
        sourceSObjectType = CDdMxOrderEventConfig.getSObjectType(event, 'source');
        sourceSObjects = new List<SObject>();
        sourceSObjectIds = new Set<Id>();
        sourceSObjectKeyApiField = CDdMxOrderEventConfig.getSObjectKeyApiField(event, 'source');
        sourceSObjectBySObjectKeyApiFieldValue = new Map<Id, SObject>();
        // Prepare Target SObject variables
        targetSObjectType = CDdMxOrderEventConfig.getSObjectType(event, 'target');
        targetSObjects = new List<SObject>();
        targetSObjectIds = new Set<Id>();
        targetSObjectKeyApiField = CDdMxOrderEventConfig.getSObjectKeyApiField(event, 'target');
        targetSObjectBySObjectKeyApiFieldValue = new Map<Id, SObject>();
        targetSObjectDmlOperation = CDdMxOrderEventConfig.getTargetSObjectDmlOperation(event);
    }
    /**
     * @description Process for Source SObjects
     * @param
     * @return
     */
    private void processForSourceSObjects(){
        // Extract Source SObject Identifiers
        if(mxOrderEvents !=null && mxOrderEvents.size()>0){
            for (Mx_Order_Event__e e : mxOrderEvents){
                sourceSObjectIds.add(e.SObject_Id__c);
            }
        }
        if(sourceObjectData.size()>0){
            for (SObject sObj : sourceObjectData){
                sourceSObjectIds.add((Id)sObj.get('Id'));
            }
        }
        // Query for Source SObjects using Source SObject Identifiers
        sourceSObjects.addAll(CDdMxOrderEventConfig.querySObjects(sourceSObjectType, 'source', 'Id', sourceSObjectIds));
        // Prepare Source SObject Map for comparison with Target SObject Map - this will result in pairing Source SObject to Target SObject
        // Additionally, extract Target SObject Identifiers
        for (SObject sourceSObject : sourceSObjects){
            if (sourceSObject.isSet(sourceSObjectKeyApiField)){
                Id sourceSObjectKeyApiFieldValue = (Id)sourceSObject.get(sourceSObjectKeyApiField);
                if (String.isNotBlank(sourceSObjectKeyApiFieldValue)){
                    sourceSObjectBySObjectKeyApiFieldValue.put(sourceSObjectKeyApiFieldValue, sourceSObject);
                    Id targetSObjectId = sourceSObjectKeyApiFieldValue;
                    targetSObjectIds.add(targetSObjectId);
                }
            }
        }        
    }
    /**
     * @description Process for Target SObjects
     * @param
     * @return
     */
    private void processForTargetSObjects(){
        // Process Target SObjects based on DML Operation (INSERT or UPDATE) for Target SObject
        switch on targetSObjectDmlOperation {
            when 'INSERT' {
                for (Id targetSObjectId : targetSObjectIds){
                    SObject targetSObject = (SObject)Type.forName(targetSObjectType).newInstance();
                    targetSObject.put(targetSObjectKeyApiField, targetSObjectId);
                    targetSObjectBySObjectKeyApiFieldValue.put(targetSObjectId, targetSObject);
                    targetSObjects.add(targetSObject);
                }
            }
            when 'UPDATE' {
                // Query for Target SObjects using Target SObject Identifiers
                targetSObjects.addAll(CDdMxOrderEventConfig.querySObjects(targetSObjectType, 'target', targetSObjectKeyApiField, targetSObjectIds));
                // Prepare Target SObject Map for comparison with Source SObject Map - this will result in pairing Source SObject to Target SObject
                for (SObject targetSObject : targetSObjects){
                    if (targetSObject.isSet(targetSObjectKeyApiField)){
                        Id targetSObjectKeyApiFieldValue = (Id)targetSObject.get(targetSObjectKeyApiField);
                        if (String.isNotBlank(targetSObjectKeyApiFieldValue)){
                            targetSObjectBySObjectKeyApiFieldValue.put(targetSObjectKeyApiFieldValue, targetSObject);
                        }
                    }
                }                         
            }
        }            
    }
    /**
     * @description Initiate copy of fields from Source SObject to Target SObject
     * Note: Perform this operation only once per Mx Order Event
     * @param
     * @return
     */
    public void execute() {
        List<SObject> targetSObjectsToInsert = new List<SObject>();
        List<SObject> targetSObjectsToUpdate = new List<SObject>();        
        for (Id sourceSObjectKeyValue : sourceSObjectBySObjectKeyApiFieldValue.keySet()){
            if (targetSObjectBySObjectKeyApiFieldValue.containsKey(sourceSObjectKeyValue)){
                SObject sourceSObject = sourceSObjectBySObjectKeyApiFieldValue.get(sourceSObjectKeyValue);
                SObject targetSObject = targetSObjectBySObjectKeyApiFieldValue.get(sourceSObjectKeyValue);
                Boolean isUpdated = CDdMxOrderEventConfig.copyFields(event, sourceSObject, targetSObject);
                switch on targetSObjectDmlOperation {
                    when 'INSERT' {
                        targetSObjectsToInsert.add(targetSObject);
                    }
                    when 'UPDATE' {
                        if (isUpdated){
                            targetSObjectsToUpdate.add(targetSObject);
                        }
                    }
                }                        
            }
        }
        if (!targetSObjectsToInsert.isEmpty()){
            insert targetSObjectsToInsert;
        }
        if (!targetSObjectsToUpdate.isEmpty()){
            update targetSObjectsToUpdate;
        }        
    }  
}