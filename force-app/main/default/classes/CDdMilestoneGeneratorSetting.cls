/********************************************************************************************************************
* @author Sriram
* @date 08/06/2021
*
* @group Milestone
*
* @description 
*   Milestone generation is enabled for sObject record, by configuring Parent sObject Types in custom metadata 'Milestone_Generator_Setting__mdt'
*   Each custom setting record has the following properties that are essential for the generation of Milestones
*   1. Parent SObject Type - what is the parent sObject Type for which the milestones are being generated?
*   2. Parent SObject Record Type - what is the parent sObject Record Type for which the milestones are being generated?
*   3. Parent SObject Reference Field - this the parent reference field found on the Milestone custom object for the specific parent sObject type
*   4. Apex Implmentation Class Name - Reflection is used to instantiate the individual Milestone Generator instance
*   Input sObject records will be processed in chunks based on their sObject type and record type
*   The corresponding Apex implementation class found in the settings will require above properties to be set within it instance
*       prior to generation of milestones
**************************************************************************************************************************************/
public class CDdMilestoneGeneratorSetting {
    /**
     * Static variables are defined here
     */
    public static final Set<Id> RECORD_TYPE_IDS_FOR_MX_ACCOUNTS = new Set<Id>{CDdSchemaUtils.ACCOUNT_RT.prospectId(), CDdSchemaUtils.ACCOUNT_RT.enterpriseMarketplaceId()};
    public static final String SOBJECT_TYPE_CASE = 'Case';    
    private static Map<Id, Set<Id>> SETTINGS_BY_CUSTOM_PERMISSION_ID;
    private static Map<Id, Milestone_Generator_Setting__mdt> MILESTONE_GENERATOR_SETTING_BY_PARENT_RECORD_TYPE_ID;
    private static String SOQL_QUERY_PARENT_SOBJECT = ' SELECT Id, RecordTypeId, CreatedDate '
                                                + ' FROM {0} '
                                                + ' WHERE Id IN :parentSObjectIds ';                                  
    private static String SOQL_QUERY_COUNT_MILESTONE_WITH_NULL_TEMPLATE = ' SELECT {0}, COUNT(Id) '
                                                                        + ' FROM Milestone__c '
                                                                        + ' WHERE {1} IN :parentSObjectIds '
                                                                        + ' AND Milestone_Template__c = NULL '
                                                                        + ' GROUP BY {2} ';                                                
    /**
     * Static variable initialization
     * - Prepare map collection Milestone Generator setting by key 'Record Type Id' of the parent sObject type
     */
    static {
        MILESTONE_GENERATOR_SETTING_BY_PARENT_RECORD_TYPE_ID = new Map<Id, Milestone_Generator_Setting__mdt>();
        SETTINGS_BY_CUSTOM_PERMISSION_ID = new Map<Id, Set<Id>>();
        Set<String> parentSObjectTypes = new Set<String>();
        Set<String> parentRecordTypeDeveloperNames = new Set<String>();
        Set<String> customPermissions = new Set<String>();
        List<Milestone_Generator_Setting__mdt> settings = new List<Milestone_Generator_Setting__mdt>();
        for (Milestone_Generator_Setting__mdt setting : [SELECT Id, MasterLabel, DeveloperName, Is_Active__c, 
                                                        Parent_SObject_Type__c, Parent_Record_Type_Developer_Name__c, Parent_SObject_Reference_Field__c,
                                                        Custom_Permission__c, Apex_Class_Implementation__c
                                                        FROM Milestone_Generator_Setting__mdt
                                                        WHERE Is_Active__c = TRUE]){
            parentSObjectTypes.add(setting.Parent_SObject_Type__c);
            parentRecordTypeDeveloperNames.add(setting.Parent_Record_Type_Developer_Name__c);
            if (String.isNotBlank(setting.Custom_Permission__c)){
                customPermissions.add(setting.Custom_Permission__c);
            }
            settings.add(setting);
        }
        for (RecordType rt : [SELECT Id, SObjectType, DeveloperName
                              FROM RecordType
                              WHERE SObjectType IN :parentSObjectTypes
                              AND DeveloperName IN :parentRecordTypeDeveloperNames]){
            for (Milestone_Generator_Setting__mdt setting : settings){
                if (rt.SObjectType.equals(setting.Parent_SObject_Type__c) && rt.DeveloperName.equals(setting.Parent_Record_Type_Developer_Name__c)){
                    MILESTONE_GENERATOR_SETTING_BY_PARENT_RECORD_TYPE_ID.put(rt.Id, setting);
                }
            }
        }
        if (!customPermissions.isEmpty()){
            for (CustomPermission cp : [SELECT Id, DeveloperName
                                        FROM CustomPermission   
                                        WHERE DeveloperName IN :customPermissions]){
                for (Milestone_Generator_Setting__mdt setting : settings){
                    if (String.isNotBlank(setting.Custom_Permission__c) && cp.DeveloperName.equals(setting.Custom_Permission__c)){
                        if (SETTINGS_BY_CUSTOM_PERMISSION_ID.containsKey(cp.Id)){
                            SETTINGS_BY_CUSTOM_PERMISSION_ID.get(cp.Id).add(setting.Id);
                        } else {
                            SETTINGS_BY_CUSTOM_PERMISSION_ID.put(cp.Id, new Set<Id>{setting.Id});
                        }
                    }
                }
            }            
        }
    }
    /**
     * @description Retrieve the parent sObject Ids and organize them in a Map collection with key as Record Type Id
     * @param String parentSObjectType - what is the parent sObject Type for which the milestones are being generated?
     * @param Set<Id> parentSObjectIds - a Collection of sObjects Ids that will be processed for milestone generation
     * @return Return a Collection of Parent sObject Ids with key as Record Type Id
     */    
    public static Map<Id, Map<Id, SObject>> getParentSObjectsByRecordTypeId(String parentSObjectType, Set<Id> parentSObjectIds) {
        String query = String.format(SOQL_QUERY_PARENT_SOBJECT, new List<String>{parentSObjectType});
        Map<Id, Map<Id, SObject>> parentSObjectIdsByRecordTypeId = new Map<Id, Map<Id, SObject>>();

        for (Sobject sObj : Database.query(query)){
            Id parentSObjectId = (Id)sObj.get('Id');
            Id parentSObjectRecordTypeId = (Id)sObj.get('RecordTypeId');

            if (parentSObjectIdsByRecordTypeId.containsKey(parentSObjectRecordTypeId)){
                parentSObjectIdsByRecordTypeId.get(parentSObjectRecordTypeId).put(parentSObjectId, sObj);
            } else {
                parentSObjectIdsByRecordTypeId.put(parentSObjectRecordTypeId, new Map<Id, SObject>{ parentSObjectId => sObj });
            }
        }
        
        return parentSObjectIdsByRecordTypeId;
    }
    /**
     * @description Return the Collection of 'Milestone Generator Setting' that is driven ONLY by custom permission
     * - User must be configured to inherit the custom permission as found on the setting
     * - If not configured, the User is not permitted to generate the milestones for that specific setting
     * Note: The collection returned will EXCLUDE the 'Milestone Generator Setting' with blank value for Custom Permission field
     * @param String userId - the user performing the action of generating milestones
     * @return Return a Collection of 'Milestone Generator Setting' that is driven ONLY by custom permission
     */     
    public static Set<Id> getUserPermittedSettings(String userId, Map<Id, Set<Id>> settingsByCustomPermissionId){
        Set<Id> userPermittedSettings = new Set<Id>();
        if (!settingsByCustomPermissionId.isEmpty()){
            Set<Id> userPermissionSetIds = new Set<Id>();
            for (PermissionSetAssignment psa : [SELECT PermissionSetId
                                                FROM PermissionSetAssignment
                                                WHERE AssigneeId = :userId
                                            ]){
                userPermissionSetIds.add(psa.PermissionSetId);
            }
            for (SetupEntityAccess s : [SELECT Id, SetupEntityId, SetupEntityType, ParentId
                                        FROM SetupEntityAccess
                                        WHERE ParentId IN :userPermissionSetIds
                                        AND (SetupEntityId IN :settingsByCustomPermissionId.keySet())]){
                if (userPermissionSetIds.contains(s.ParentId)){
                    userPermittedSettings.addAll(settingsByCustomPermissionId.get(s.SetupEntityId));
                }
            }
        }
        return userPermittedSettings;
    }   
    /**
     * @description A static operation that returns a Milestone Generator setting for an input record type id
     * NOTE: Null is returned, 
     * - if the Milestone Generator setting is not found for a sObject type and the corresponding record type
     * @param Id parentSObjectRecordTypeId - Parent sObject Record Type Id
     * @return <Milestone_Generator_Setting__mdt> Return the custom metadata setting record
     */     
    public static Milestone_Generator_Setting__mdt getMilestoneGeneratorSetting(Id parentSObjectRecordTypeId){
        return MILESTONE_GENERATOR_SETTING_BY_PARENT_RECORD_TYPE_ID.containsKey(parentSObjectRecordTypeId)
            ?  MILESTONE_GENERATOR_SETTING_BY_PARENT_RECORD_TYPE_ID.get(parentSObjectRecordTypeId)
            :  null;  
    }
    /**
     * @description  Return a Collection of Milestone Generator Setting with key as Parent Record Type Identifier
     * For each record type id, 
     * - the corresponding Milestone Generator Setting is obtained
     * - if the setting is configured with custom permission
     *      - an additional check is performed if the input User Id is permitted to generate the milestone for this setting
     * @param String userId - the user performing the action of generating milestones
     * @param Set<Id> parentSObjectRecordTypeIds - a Collection of Parent SObject Record Type Ids
     * @return Map<Id, Milestone_Generator_Setting__mdt> Return a Collection of Milestone Generator Setting with key as Parent Record Type Identifier
     */      
    public static Map<Id, Milestone_Generator_Setting__mdt> getMilestoneGeneratorSettingByRecordTypeId(String userId, Set<Id> parentSObjectRecordTypeIds){
        Set<Id> userPermittedSettings = getUserPermittedSettings(userId, SETTINGS_BY_CUSTOM_PERMISSION_ID);
        Map<Id, Milestone_Generator_Setting__mdt> milestoneGeneratorSettingByRecordTypeId = new Map<Id, Milestone_Generator_Setting__mdt>();
        for (Id parentSObjectRecordTypeId : parentSObjectRecordTypeIds){
            Milestone_Generator_Setting__mdt setting = getMilestoneGeneratorSetting(parentSObjectRecordTypeId);
            if (setting!=null && (String.isBlank(setting.Custom_Permission__c) || userPermittedSettings.contains(setting.Id))){
                milestoneGeneratorSettingByRecordTypeId.put(parentSObjectRecordTypeId, setting);
            }
        }
        return milestoneGeneratorSettingByRecordTypeId;
    }
    /**
     * @description A static operation that return an instance of the Milestone Generation for the input apex class name
     * Note: The apex implementation class must implement the interface <CDdMilestoneGenerator>
     * @param String milestoneGeneratorApexClassName - apex implementation class name for milestone generation
     * @return Return an instance of <CDdMilestoneGenerator>
     */       
    public static CDdMilestoneGenerator getMilestoneGeneratorInstance(String milestoneGeneratorApexClassName){
        return (CDdMilestoneGenerator)Type.forName(milestoneGeneratorApexClassName).newInstance();
    }                  
    /**
     * @description Generate milestones for each individual Collection of parent sObject records partitioned by a specific record type
     * There are specific Milestone Generator Apex classes configured within settings to handle the milestone generation for 
     * specific combination of Parent SObject Type and Parent SObject Record Type
     * a) Reflection is used to instantiate the individual Milestone Generator instances
     * b) Parent SObject Attributes are set on the Milestone Generator instance
     * c) Filter the Parent SObject Record Ids to exclude any from processing
     * d) Set the filtered Parent SObject Record Ids on the Milestone Generator instance
     * e) Finally, instruction is sent to the Milestone Generator instance to generate the milestones by firing the execute() operation on the instance
     * NOTE: On the Milestone Generator instance, set the parent attributes first before you the set parent sObject record Ids
     * @param String userId - the user performing the action of generating milestones
     * @param String parentSObjectType - what is the parent sObject Type for which the milestones are being generated?
     * @param Set<Id> parentSObjectIds - a Collection of sObjects Ids that will be processed for milestone generation
     * @return 
     */      
    public static void generateMilestones(String userId, String parentSObjectType, Set<Id> parentSObjectIds){
        Map<Id, Map<Id, SObject>> parentSObjectsByRecordTypeId = getParentSObjectsByRecordTypeId(parentSObjectType, parentSObjectIds);
        Map<Id, Milestone_Generator_Setting__mdt> milestoneGeneratorSettingByRecordTypeId 
                                    = getMilestoneGeneratorSettingByRecordTypeId(userId, parentSObjectsByRecordTypeId.keySet());

        for (Id parentSObjectRecordTypeId : milestoneGeneratorSettingByRecordTypeId.keySet()){
            Milestone_Generator_Setting__mdt setting = milestoneGeneratorSettingByRecordTypeId.get(parentSObjectRecordTypeId);
            CDdMilestoneGenerator milestoneGenerator = getMilestoneGeneratorInstance(setting.Apex_Class_Implementation__c);
            String parentSObjectReferenceField = setting.Parent_SObject_Reference_Field__c;
            
            Map<Id, SObject> parentSObjectsToProcess = parentSObjectsByRecordTypeId.get(parentSObjectRecordTypeId);

            for(Id parentToExcludeId : getParentSObjectIdsToExcludeFromProcessing(parentSObjectReferenceField, parentSObjectsToProcess.keySet())) {
                parentSObjectsToProcess.remove(parentToExcludeId);
            }

            milestoneGenerator.setParentAttributes(parentSObjectType, parentSObjectRecordTypeId, parentSObjectReferenceField);
            milestoneGenerator.setParentSObjectRecords(parentSObjectsToProcess);
            milestoneGenerator.execute();
        }
    }
    /**
     * @description Create Milestones for the eligible Parent SObject Records
     * 1. Partition the input Parent SObject Record Ids by Parent SObject Record Type Id 
     * 2. Retrieve the eligible Parent SObject Record Type Ids for Milestone Generation
     *      a) Retrieve the records from Milestone Generator Settings custom metadata
     *      b) Check if the input Parent SObject Record Type Id is configured in custom metadata
     *      c) If configured in custom metadata and a custom permission is set, then perform additional
     *          security check to ensure the User inherits the custom permission and thereby permitted
     *          to generate milestone records
     * 3. Check if the input the Parent SObject Record Id is elibile for milestone generation, 
     *      based its record type id found in the collection of eligible Parent SObject Record Type Ids (Step 2)
     * 4. Add the eligible Parent SObject Record Ids to the Collection of Milestone Platform Events
     * 5. Finally, fire the platform events that will results in creation of Milestone records
     * @param String parentSObjectType - what is the parent sObject Type for which the milestones are being created?
     * @param Set<Id> parentSObjectIds - a Collection of sObjects Ids that will be processed for milestone creation
     * @return 
     */      
    public static void createMilestones(String parentSObjectType, Set<Id> parentSObjectIds){
        Map<Id, Map<Id, SObject>> parentSObjectIdsByRecordTypeId = getParentSObjectsByRecordTypeId(parentSObjectType, parentSObjectIds);
        Map<Id, Milestone_Generator_Setting__mdt> milestoneGeneratorSettingByRecordTypeId 
                                    = getMilestoneGeneratorSettingByRecordTypeId(UserInfo.getUserId(), parentSObjectIdsByRecordTypeId.keySet());
        Map<Id, Milestone_Event__e> milestoneEvents = new Map<Id, Milestone_Event__e>();
        for (Id parentSObjectRecordTypeId : milestoneGeneratorSettingByRecordTypeId.keySet()){
            for(Id parentSObjectId :  parentSObjectIdsByRecordTypeId.get(parentSObjectRecordTypeId).keySet()){
                milestoneEvents.put(parentSObjectId, new Milestone_Event__e(Operation__c = 'Insert', User_Id__c = UserInfo.getUserId(), Parent_SObject_Type__c = parentSObjectType, Parent_SObject_Id__c = parentSObjectId));
            }
        }
        if (!milestoneEvents.isEmpty()){
            EventBus.publish(milestoneEvents.values());
        }                
    }
    /**
     * @description Create Milestones for Case Records that belong to Mx Accounts i.e. (Enterprise Marketplace or Marketplace)
     * 1. Receive the input Parent Accounts 
     * 2. Filter the Case records that belong to Mx Accounts of the input Parent Accounts
     * 3. Invoke the createMilestones operation for the filtered collection of Case Record Identifiers
     * @param Set<Id> parentAccountIdsForMxAccounts - a Collection of Parent Account sObjects Ids that will be processed for case milestone creation
     * @return 
     */      
    public static void createCaseMilestonesForMxAccounts(Set<Id> parentAccountIds){
        Set<Id> caseIds = new Set<Id>();
        for (Case c :   [   SELECT Id 
                            FROM Case 
                            WHERE AccountId IN 
                            (   SELECT Id 
                                FROM Account 
                                WHERE ParentId IN :parentAccountIds
                                AND RecordTypeId IN :RECORD_TYPE_IDS_FOR_MX_ACCOUNTS 
                            )
                            LIMIT :CDdMxSxConstants.getMaxRowsToProcess()
                        ]){
            caseIds.add(c.Id);
        }
        if (!caseIds.isEmpty()){
            createMilestones(SOBJECT_TYPE_CASE, caseIds);
        }
    }  
    /**
     * @description BASD-16073 - Prevent milestone generation for Parent SObject records that were worked on previously for backdated milestones 
     * @param String parentSObjectReferenceField - this the parent reference field found on the Milestone custom object for the specific parent sObject type
     * @param Set<Id> parentSObjectIds - a Collection of sObjects Ids that is filtered further prior to processing for milestone generation
     * @return Return a Collection of Parent sObject Ids to be excluded from processing
     */    
    public static Set<Id> getParentSObjectIdsToExcludeFromProcessing(String parentSObjectReferenceField, Set<Id> parentSObjectIds) {
        String query = String.format(SOQL_QUERY_COUNT_MILESTONE_WITH_NULL_TEMPLATE, new List<String>{parentSObjectReferenceField, parentSObjectReferenceField, parentSObjectReferenceField});
        Set<Id> parentSObjectIdsToExcludeFromProcessing = new Set<Id>();
        for (AggregateResult ar : Database.query(query)){
            Id parentSObjectId = (Id)ar.get(parentSObjectReferenceField);
            Integer milestoneWithNullTemplateCount = (Integer)ar.get('expr0');
            if (milestoneWithNullTemplateCount>0){
                parentSObjectIdsToExcludeFromProcessing.add(parentSObjectId);
            }
        }
        return parentSObjectIdsToExcludeFromProcessing;
    }      
}