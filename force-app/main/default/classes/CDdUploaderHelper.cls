/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 1/27/2020.
 *
 * Process a csv string and return the result in a Context object that includes information
 * about the request, the intermediate steps, and validation results.
 */

public with sharing class CDdUploaderHelper {
    private static final String CLASS_NAME = 'CDdUploaderHelper';    
    private final Map<String, Schema.SObjectType> typeMap = Schema.getGlobalDescribe();
    private static CDdNimdaSyncMSService msService = new CDdNimdaSyncMSService();
    /**
     * Accept a CSV string, parse it into a CDdUploaderCSV object, validate it, convert it to SObjects (for batch updates)
     * and a JSON array (for binding composite objects on the UI), and store results in CDdUploaderContext
     *
     * @param ctx CDdUploaderContext
     * @return CDdUploaderContext
     */
    public CDdUploaderContext uploadCsv(CDdUploaderContext ctx) {
        Map<String, List<SObject>> allObjects = new Map<String, List<SObject>>();
        ctx.csv = new CDdUploaderCSV(ctx.csvRaw);
        ctx.isImportable = ctx.csv.isImportable;
        ctx.isCompositeUpdate = ctx.csv.isCompositeObject;
        ctx.columns = ctx.csv.header.columnNames;
        // Import the file only if the file is importable
        if (ctx.isImportable){
            this.validateCsv(ctx);

            // Initialize the allObjects map; these will be added to ctx.updateList for batch update
            for (String objectName : ctx.csv.header.objectMap.keySet()) {
                allObjects.put(objectName, new List<SObject>());
            }

            // Iterate over rows, create new SObjects, and bind cell values to them
            for (CDdUploaderCSV.Row row : ctx.csv.rows) {
                Map<String, Object> dataTableRow = new Map<String, Object>();
                dataTableRow.put('rowKey', row.rowKey);

                // Initialize rowObjectMap map for binding cells to correct SObjects
                Map<String, SObject> rowObjectMap = new Map<String, SObject>();
                for (String objectName : ctx.csv.header.objectMap.keySet()) {
                    SObject obj = typeMap.get(objectName).newSObject();

                    // Set Platform Event control fields
                    if ('Account'.equals(objectName)) {
                        obj.put('MS_Sync_Stage__c', 'Processing');
                        obj.put('MS_Sync_Status__c', 'Platform Event Generated');
                        obj.put('MS_Error_Message__c', null);
                    }

                    rowObjectMap.put(objectName, obj);
                }

                // Iterate over cells and assign their values to the appropriate SObject
                for (CDdUploaderCSV.Cell cell : row.cells) {
                    SObject obj = rowObjectMap.get(cell.meta.objectName);
                    try {
                        dataTableRow.put(cell.meta.objectFieldName, cell.value);
                        bindValue(cell, obj);
                    } catch (Exception e) {
                        ctx.csv.addRowError(row, cell, 'Unable to convert value: ' + cell.value + ', ' + e.getMessage());
                    }
                }

                // Set AccountId on Opportunities in order to group by Account across multiple rows
                if (ctx.isCompositeUpdate && rowObjectMap.keySet().contains('Opportunity')) {
                    String accountId = (String) rowObjectMap.get('Account').get('Id');
                    rowObjectMap.get('Opportunity').put('AccountId', accountId);
                }

                // Add row rowObjectMap to the allObjects map
                for (String objectName : rowObjectMap.keySet()) {
                    allObjects.get(objectName).add(rowObjectMap.get(objectName));
                }

                // Add row to dataTable for UI preview
                ctx.dataTable.add(dataTableRow);
            }

            // Set additional fields on the Opportunity records and perform validation on opportunity records
            if (allObjects.containsKey(CDdUploaderConstants.SOBJECT_TYPE_OPPPORTUNITY) 
                    && !allObjects.get(CDdUploaderConstants.SOBJECT_TYPE_OPPPORTUNITY).isEmpty()){
                setAdditionalFieldsOnOpportunity(allObjects.get(CDdUploaderConstants.SOBJECT_TYPE_OPPPORTUNITY));
                validateOpportunities(ctx, allObjects.get(CDdUploaderConstants.SOBJECT_TYPE_OPPPORTUNITY));
            }

            // For Batchable updates, sort by SObject type and remove duplicate Accounts.
            ctx.updateListByType = groupObjectsByType(ctx.csv, allObjects);

            // To support atomic transactions across object types, organize objects as a Map of related objects
            ctx.updateListByGroup = groupObjectsByParent(allObjects, ctx.isCompositeUpdate);

            // Get the parent accounts to determine if Create Business callout exceeds the configured limit
            if (Test.isRunningTest() || CDdUploaderConstants.ENABLE_S2N_CREATE_BUSINESS){
                List<Account> parentAccounts = this.getParentAccounts(ctx.updateListByGroup.keySet(), CDdUploaderConstants.BULK_UPLOADER_CREATE_BIZ_MIN_CHILDCOUNT);
                if (parentAccounts.size() > CDdUploaderConstants.BULK_UPLOADER_CREATE_BUSINESS_LIMIT){
                    ctx.csv.addTableError(CDdUploaderConstants.BULK_UPLOADER_CREATE_BUSINESS_ERROR_MSG);
                }
            }        
        }
        return ctx;
    }

    /**
     * Convert a Map of Lists to a List with parents listed first and duplicate parents removed.
     *
     * @param csv CSV object
     * @param allObjects Map of objects by type
     * @return List<SObject>
    */
    @TestVisible
    private List<SObject> groupObjectsByType(CDdUploaderCSV csv, Map<String, List<SObject>> allObjects) {
        List<SObject> updateListByType = new List<SObject>();

        if (allObjects.keySet().contains('Account')) {
            updateListByType.addAll(this.dedupeObjects(allObjects.get('Account')));
        }

        for (String objectName : allObjects.keySet()) {
            if (!'Account'.equals(objectName)) {
                updateListByType.addAll(allObjects.get(objectName));
            }
        }

        return updateListByType;
    }

    /**
     * Create a Map of Maps that group related objects.
     *
     * If the CSV contains multiple objects types, the outer Map is keyed by Account.Id and the inner Map is keyed
     * by the related object Id. The inner Map includes the Account and its children.
     *
     * If the CSV contains only one object type, the outer and inner maps are keyed by
     * the same Id, and the inner Map consists of a single object.
     *
     * @param allObjects Map of objects by type
     * @param isCompositeUpdate Whether allObjects contains multiple object types
     * @return Map<Id, Map<Id, SObject>>
    */
    @TestVisible
    private Map<Id, Map<Id, SObject>> groupObjectsByParent(Map<String, List<SObject>> allObjects, Boolean isCompositeUpdate) {
        Map<Id, Map<Id, SObject>> outerMap = new Map<Id, Map<Id, SObject>>();

        for (List<SObject> objects : allObjects.values()) {
            for (SObject obj : objects) {
                Id id = (Id) obj.get('Id');

                if (isCompositeUpdate) { // group by account
                    Boolean isAccount = 'Account'.equals(obj.getSObjectType().getDescribe().getName());
                    String accountId = isAccount ? id : (String) obj.get('AccountId');

                    if (outerMap.containsKey(accountId)) {    // add to existing inner Map
                        outerMap.get(accountId).put(id, obj);
                    } else {                                  // add new inner Map
                        outerMap.put(accountId,  new Map<Id, SObject>{ id => obj });
                    }

                } else {
                    outerMap.put(id,  new Map<Id, SObject>{ id => obj });
                }
            }
        }

        return outerMap;
    }

    /**
     * Identify the cell's data type, convert it, and assign it to the object
     *
     * @param cell CDdUploaderCSV.Cell, including it's metadata (object, field, SF type)
     * @param obj The Salesforce SObject for this cell
     */
    public void bindValue(CDdUploaderCSV.Cell cell, SObject obj) {
        String fieldName = cell.meta.fieldName;

        // Nullify the value if requested
        if (''.equals(cell.value.toLowerCase()) || 'null'.equals(cell.value.toLowerCase())) {
            obj.put(fieldName, null);
            return;
        }

        // Otherwise convert the value to the appropriate data type
        switch on cell.meta.displayTypeSf {
            when COMBOBOX, ENCRYPTEDSTRING, EMAIL, ID, JSON, PHONE, REFERENCE, STRING, TEXTAREA, URL {
                obj.put(fieldName, cell.value);
                if (cell.meta.isId) {
                    String actualType = Id.valueOf(cell.value).getSobjectType().getDescribe().name;
                    if (!cell.meta.objectName.equals(actualType)) {
                        throw new System.TypeException('Id does not map to the object indicated. Indicated: ' + cell.meta.objectName + ', Actual: ' + actualType);
                    }
                }
            }
            when PICKLIST, MULTIPICKLIST {
                if (cell.meta.picklistEntries.contains(cell.value)) {
                    obj.put(fieldName, cell.value);
                } else {
                    throw new System.TypeException('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, bad value for restricted picklist field: ' + cell.value + ': [' + fieldName + ']');
                }
            }
            when INTEGER {
                obj.put(fieldName, Integer.valueOf(cell.value));
            }
            when LONG {
                obj.put(fieldName, Long.valueOf(cell.value));
            }
            when CURRENCY, DOUBLE {
                obj.put(fieldName, Double.valueOf(cell.value));
            }
            when PERCENT {
                obj.put(fieldName, Double.valueOf(cell.value));
            }
            when DATE {
                obj.put(fieldName, Date.valueOf(cell.value));
            }
            when DATETIME {
                obj.put(fieldName, Datetime.valueOf(cell.value));
            }
            when TIME {
                String[] parts = cell.value.split(':');
                if (parts.size() != 3) {
                    throw new System.TypeException('Time must be in the format hh:mm:ss');
                }
                obj.put(fieldName, Time.newInstance(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]), Integer.valueOf(parts[2]), 0));
            }
            when BOOLEAN {
                // Boolean.valueOf defaults to false when not some form of the string "True" or "False", e.g. 0 and 1 are both false
                String strValue = cell.value.toLowerCase();
                if (!(new String[] { '', '0', '1', 'true', 'false' }).contains(strValue) ) {
                    throw new System.TypeException();
                }

                strValue = '0'.equals(strValue) ? 'false' : strValue;
                strValue = '1'.equals(strValue) ? 'true'  : strValue;

                obj.put(fieldName, Boolean.valueOf(strValue));
            }
            when else {
                // The following are currently unsupported: ADDRESS, ANYTPE, BASE64, COMPLEXVALUE, DATACATEGORYGROUPREFERENCE, LOCATION, SOBJECT
                throw new System.TypeException('Data type not supported: ' + cell.meta.displayTypeSf.name());
            }
        }
    }

    /**
     * Perform context-specific validations of the CSV.
     *
     * @param ctx Execution context
     */
    public void validateCsv(CDdUploaderContext ctx) {
        MSSyncStage msSyncStageEnum = ctx.msSyncStageEnum;

        // CSV header values must be defined in Uploader_Field_Map__mdt
        for (CDdUploaderCSV.ColumnMeta cm : ctx.csv.header.columnMap.values()) {
            if (!CDdS2NUtil.isPermissibleField(cm.objectFieldName.trim())) {
                ctx.csv.addTableError('Unable to import field (not supported): ' + cm.objectFieldName);
            }
        }

        // Some fields are required
        if (!ctx.csv.header.columnNames.contains('Account.Id')) {
            ctx.csv.addTableError('Missing required field: Account.Id');
        }
        if (!ctx.csv.header.columnNames.contains('Opportunity.Id')) {
            ctx.csv.addTableError('Missing required field: Opportunity.Id');
        }

        // BZAP-10635 - Allow permissible fields (from custom metadata) for Full Onboarding and P&P
        /*switch on msSyncStageEnum {
            when FullOnboardingCreate, ProductAndPricingOnboarding {
                for (List<CDdUploaderCSV.ColumnMeta> cms : ctx.csv.header.objectMap.values()) {
                    if (cms.size() > 1) {
                        for (CDdUploaderCSV.ColumnMeta cm : cms) {
                            if (!cm.isId) {
                                ctx.csv.addTableError(ctx.msSyncStageStr + ' only accepts Id values. Please remove non-Id field: ' + cm.objectFieldName);
                            }
                        }
                    }
                }
            }
        }*/

        // Full Onboarding Update requires at least one non-Id field to update.
        /*
        if (MSSyncStage.FullOnboardingUpdate.equals(msSyncStageEnum) && (!ctx.csv.isUpdate)) {
            ctx.csv.addTableError('Full Onboarding Update requires at least one non-Id field to update.');
        }
         */

    }
    /** 
     * @description Perform validations on Opportunity records
     * - Example: Opportunity record stage must be Closed Won
     * @param CDdUploaderContext Uploader Context Object
     * @param List<SObject> Collection of Opportunity records
     * @return
     */
    public static void validateOpportunities(CDdUploaderContext ctx, List<SObject> opportunities){
        Map<Id, CDdUploaderCSV.Cell> cellMap = ctx.csv.idsByObject.get(CDdUploaderConstants.SOBJECT_TYPE_OPPPORTUNITY);
        if (cellMap != null) {
            for (SObject opp : opportunities) {
                CDdUploaderCSV.Cell cell = cellMap.get(opp.Id);
                if (!CDdUploaderConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(
                                            opp.get(CDdUploaderConstants.OPPORTUNITY_FIELD_API_NAME_STAGE_NAME))){
                    ctx.csv.addRowError(cell.row, cell, CDdUploaderConstants.ERROR_MESSAGE_OPPORTUNITY_STAGE_NOT_CLOSED_WON);
                }
            }
        }
    }
    /**
     * Sort the list of SObjects by Id and keep the first SObject. The default List.sort()
     * doesn't sort on Id, so use an SObjectWrapper that implements Comparable and sorts by Id.
     *
     * @param objectList Hybrid list of SObjects
     * @return List<SObject>
     */
    public List<SObject> dedupeObjects(List<SObject> objectList) {
        List<SObject> dedupedList = new List<SObject>();
        List<SObjectWrapper> wrapperList = new List<SObjectWrapper>();

        // Cast List<SObject> to List<SObjectWrapper> and sort
        for (SObject obj : objectList) {
            if (obj.Id != null) {
                wrapperList.add((new SObjectWrapper(obj)));
            }
        }
        wrapperList.sort();

        // Evaluate Ids and only add unique Accounts
        String id = '';
        for (SObjectWrapper wrapper : wrapperList) {
            if (!id.equals(wrapper.obj.Id)) {
                dedupedList.add(wrapper.obj);
                id = wrapper.obj.Id;
            }
        }

        return dedupedList;
    }

    /**
     * Comparable Wrapper to sort SObjects by Id
     */
    public class SObjectWrapper implements Comparable {
        public SObject obj;

        public SObjectWrapper(SObject obj) {
            this.obj = obj;
        }

        public Integer compareTo(Object compareTo) {
            SObjectWrapper compareToObject = (SObjectWrapper) compareTo;
            if (obj.Id > compareToObject.obj.Id) {
                return 1;
            } else {
                return -1;
            }
        }
    }
   /**
     * Create Business for the input Parent Accounts
     * Throw an Exception, if MuleSoft 'Create Business' API returns an error
     * @param referenceId, an identifier used to extract error messages from Apex Logs (Example: batch Job Id)
     * @param parentAccounts, a Collection of Parent Accounts
     * @return 
     */
    public void createBusiness(String referenceId, List<Account> parentAccounts) {
        String METHOD_NAME = 'createBusiness';
        if (!Test.isRunningTest() && !CDdUploaderConstants.ENABLE_S2N_CREATE_BUSINESS) { return; }       
        List<Account> accountsToUpdate = new List<Account>();
        try {
            for (Account a : parentAccounts){
                Integer businessId = msService.createBusiness(a.Name);
                if (businessId!=null){
                    accountsToUpdate.add(new Account(Id = a.Id, Business_Id__c = businessId));
                }
            }
        } catch(Exception e){
            List<Apex_Log__c> errors = new List<Apex_Log__c>();
            errors.add(new Apex_Log__c(Class_Name__c = CLASS_NAME, Method_Name__c = METHOD_NAME, Reference_Id__c = referenceId, Log__c = e.getMessage()));
            Database.insert(errors, false);            
            throw e;
        } finally {
            if (!accountsToUpdate.isEmpty()){
                this.dmlUpdate(CLASS_NAME, METHOD_NAME, referenceId, accountsToUpdate);
            }
        }
    }
   /**
     * Get Parent Accounts associated with the input Collection of Child Accounts
     * Note: Include only those Parent Accounts for processing (i.e Creation of Business) where
     * 1. A valid Parent Account is found on the corresponding Child Account
     * 2. Business Id of the Parent Account is either NULL or contains the Default Value
     * 3. Parent has atleast the minimum Child Account count in the input collection
     * @param childAccountIds a Collection of unique child account record identifiers
     * @param minChildAccount an Integer Collection of unique child account record identifiers     
     * @return List<Account> a Collection of Parent Accounts
     */    
    public List<Account> getParentAccounts(Set<Id> childAccountIds, Integer minChildAccount){
        List<Account> parentAccounts = new List<Account>();
        AggregateResult[] results = [SELECT COUNT(Id) childAccountCount, 
                                        ParentId parentAccountId, 
                                        Parent.Name parentAccountName
                                    FROM Account 
                                    WHERE Id IN :childAccountIds 
                                    AND ParentId != NULL
                                    AND (Parent.Business_Id__c = NULL)
                                    GROUP BY ParentId, Parent.Name];
        for (AggregateResult ar : results) {
            if ((Integer)ar.get('childAccountCount') >= minChildAccount){
                parentAccounts.add(new Account(
                                        Id = (Id)ar.get('parentAccountId'),
                                        Name = (String)ar.get('parentAccountName')
                                    ));
            }
        }
        return parentAccounts;                
    }
   /**
     * Perform DML Update
     * @param className, Apex Class Name
     * @param methodName, Apex Method Name
     * @param referenceId, an identifier used to extract error messages from Apex Logs (Example: batch Job Id)
     * @param sObjs, a Collection of sObject records to update 
     * @return 
     */    
    public void dmlUpdate(String className, String methodName, String referenceId, List<SObject> sObjs){
        Database.SaveResult[] results = Database.update(sObjs, false);
        List<Apex_Log__c> errors = new List<Apex_Log__c>();
        for(Integer i=0;i<results.size();i++){
            Database.SaveResult result = results.get(i);
            if (!result.isSuccess()){
                Database.Error error = result.getErrors().get(0);
                String errorMessage = error.getMessage();
                SObject sObj = sObjs.get(i);
                Id recordId = sObj.isSet('Id') ? (Id)sObj.get('Id') : null;
                errors.add(new Apex_Log__c(Class_Name__c = className, Method_Name__c = methodName, Reference_Id__c = referenceId, Log__c = 'Unable to update record Id ' + recordId + ' : ' + error.message));
            }                
        }
        if (!errors.isEmpty()){
            Database.insert(errors, false);
        }        
    }
    /**
     * @description Set additional fields on the Opportunity records 
     * These additional fields on the Opportunity record are not available via the uploaded CSV file by the User
     * However, these fields would be required for
     * - Performing validations such as 
     *      - Opportunity should not be processed if it is not closed won
     * - Utilizing the injected fields for downstream processing such as 
     *      - Availability of Primary Quote Id for S2N Bulk Platform Event
     * @param List<SObject> opportunities - a collection of Opportunity Records
     * @return 
     */    
    public static void setAdditionalFieldsOnOpportunity(List<SObject> opportunities){
        Set<Id> opportunityIds = new Set<Id>();
        for (SObject sObj : opportunities){
            opportunityIds.add((Id)sObj.get(CDdUploaderConstants.SOBJECT_FIELD_API_NAME_ID));
        }
        Map<Id, Opportunity> opportunitiesWithAdditionalFields = getOpportunities(opportunityIds);
        for (SObject sObj : opportunities){
            Id opportunityId = (Id)sObj.get(CDdUploaderConstants.SOBJECT_FIELD_API_NAME_ID);
            if (opportunitiesWithAdditionalFields.containsKey(opportunityId)){
                Opportunity opportunityWithAdditionalFields = opportunitiesWithAdditionalFields.get(opportunityId);
                for (String additionalField : CDdUploaderConstants.OPPORTUNITY_ADDITIONAL_FIELDS){
                    sObj.put(additionalField, opportunityWithAdditionalFields.get(additionalField));
                }
            }
        }
    }        
    /**
     * @description Get Opportunity records to store additional fields in Context
     * @param Set<Id> opportunityIds - a collection of Opportunity Record Ids
     * @return Map<Id, Opportunity> - Return a Map collection of Opportunity records with Key as Opportunity Record Id
     */
    public static Map<Id, Opportunity> getOpportunities(Set<Id> opportunityIds){
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>();
        for (Opportunity opp : Database.query(CDdUploaderConstants.SOQL_QUERY_OPPORTUNITY_FOR_ADDITIONAL_FIELDS)) {
            opportunities.put(opp.Id, opp);
        }
        return opportunities;
    }
}