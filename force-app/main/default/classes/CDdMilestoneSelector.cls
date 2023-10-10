/**
 * @author Jeremy S. Johnson
 * @date November 2020
 *
 * @description BZAP-6164 Selector pattern class for Milestone__c and Milestone_Template__c.
 * @see https://trailhead.salesforce.com/en/content/learn/modules/apex_patterns_dsl/apex_patterns_dsl_learn_selector_l_principles
 */
public with sharing class CDdMilestoneSelector {
    private static Map<String, List<Id>> settingsCache = new map<String, List<Id>>();
    public static Map<String, List<String>> settingsStatusRollup = new Map<String, List<String>>();
    private static Map<String, Milestone_Setting__mdt> milestoneSettings;

    public static Map<Id, SObject> parentMap(Set<Id> ids) {
        Map<Id, SObject> sobjectMap = new Map<Id, SObject>();

        // TODO: Activation_Date_2__c is Case-specific
        String sobjectType = CDdSchemaUtils.getSObjectTypeNameFromRecordId((Id) ids.iterator().next());
        String soql = String.format('select Id, POS_Integration_Type__c, Status, Stage__c, Segment__c, Status_Reason__c, Historical_Delay_Reasons__c, Activation_Date_2__c, Account.BillingCountryCode, Account.Parent.Parent.RecordTypeId, RecordTypeId, Origin, CreatedById,CreatedBy.Name, OwnerId from {0} where Id =:ids', new List<Object> { sobjectType });
        System.debug('CDdMilestone.parentObjsMapById, soql: ' + soql);

        List<SObject> sobjects = Database.query(soql);
        for (SObject sobj : sobjects) {
            sobjectMap.put((String) sobj.get('Id'), sobj);
        }

        return sobjectMap;
    }

    public static List<String> settingsRecordTypeIds(String sobjectType) {
        if (!settingsCache.containsKey(sobjectType)) {
            Milestone_Setting__mdt setting = getMilestoneSettings(sobjectType);
            List<Id> ids = new List<Id>();
            for (String developerName : setting.Record_Type_Developer_Names__c.deleteWhitespace().split(',')) {
                ids.add(CDdSchemaUtils.getRecordTypeIdByDeveloperName(sobjectType, developerName));
            }
            settingsCache.put(sobjectType, ids);
        }
        return settingsCache.get(sobjectType);
    }

    public static List<String> settingsStatusRollup(String sobjectType) {
        if (!settingsStatusRollup.containsKey(sobjectType)) {
            Milestone_Setting__mdt setting = getMilestoneSettings(sobjectType);
            List<String> statuses = new List<String>();
            if (!String.isEmpty(setting.Eligible_Milestone_Status__c)) {
                statuses.addAll(setting.Eligible_Milestone_Status__c.deleteWhitespace().split(','));
            }
            settingsStatusRollup.put(sobjectType, statuses);
        }
        return settingsStatusRollup.get(sobjectType);
    }

    private static Milestone_Setting__mdt getMilestoneSettings(String sobjectType) {
        if (milestoneSettings == null) {
            milestoneSettings = new Map<String, Milestone_Setting__mdt>();
            for (Milestone_Setting__mdt setting: [select SObject__c, Record_Type_Developer_Names__c, Eligible_Milestone_Status__c from Milestone_Setting__mdt]) {
                milestoneSettings.put(setting.SObject__c, setting);
            }
        }
        return milestoneSettings.get(sobjectType);
    }

    public static Map<Id, List<Milestone__c>> milestonesForInitialStageByParentId(Set<Id> parentIds) {
        return listToMappedList(milestonesForInitialStage(parentIds), 'ParentId__c');
    }

    public static List<Milestone__c> milestonesForInitialStage(Set<Id> parentIds) {
        return [
                select
                        Completed_by_Stage__c,
                        Id,
                        Milestone_Template__c,
                        Milestone_Type__c,
                        OwnerId,
                        ParentId__c,
                        RecordTypeId,
                        Reviewed_by_Stage__c,
                        Sort_Order__c,
                        Status__c,
                        Status_Reason__c,
                        Status_Reason_Details__c,
                        Stage_Completed_Sort_Order__c,
                        Stage_Reviewed_Sort_Order__c
                from Milestone__c
                where ParentId__c = :parentIds
                    and Status__c = 'Not Started'
                    and ((Stage_Completed_Sort_Order__c = 1 and Completed_by_Stage__c != null) or
                         (Stage_Reviewed_Sort_Order__c = 1 and Reviewed_by_Stage__c != null))
                order by Sort_Order__c, Stage_Completed_Sort_Order__c, Stage_Reviewed_Sort_Order__c
        ];
    }

    /**
     * @param ids The parent Ids for which to get milestones
     *
     * @return A Map of milestones keyed by parent Id
     */
    public static Map<Id, List<Milestone__c>> milestoneMapByParentId(Set<Id> ids) {
        return listToMappedList(milestonesByParentId(ids), 'ParentId__c');
    }

    /**
     * @param parentIds The parent Ids for which to get milestones
     *
     * @return A List of milestones
     */
    public static List<Milestone__c> milestonesByParentId(Set<Id> parentIds) {
        return [
                select
                        Completed_by_Stage__c,
                        Historical_Delay_Reasons__c,
                        Id,
                        Milestone_Template__c,
                        Milestone_Type__c,
                        OwnerId,
                        ParentId__c,
                        RecordTypeId,
                        Reviewed_by_Stage__c,
                        Sort_Order__c,
                        Status__c,
                        Status_Reason__c,
                        Status_Reason_Details__c,
                        Stage_Completed_Sort_Order__c,
                        Stage_Reviewed_Sort_Order__c
                from Milestone__c
                where ParentId__c = :parentIds
                order by Sort_Order__c, Stage_Completed_Sort_Order__c, Stage_Reviewed_Sort_Order__c
        ];
    }  

    public static Map<Id, Milestone_Template__c> templatesByParentTypeMap(String parentType) {
        return new Map<Id, Milestone_Template__c>([
            select
                Active__c,
                Completed_by_Stage__c,
                Default_Milestone_Status_on_Creation__c,
                Default_Owner_on_Creation_18__c,
                Default_Sort_Order__c,
                Id,
                Milestone_Creation_Type__c,
                Milestone_Record_Type_ID_18__c,
                Milestone_Type__c,
                Parent_Object_API_Name__c,
                Parent_Object_Record_Type_ID_18__c,
                Reviewed_by_Stage__c,
                Stage_Completed_Sort_Order__c,
                Stage_Reviewed_Sort_Order__c
                from Milestone_Template__c
        where
            Parent_Object_API_Name__c = :parentType
                and Active__c = true
                order by Default_Sort_Order__c]);
    }

    /**
        @author: Dan Thoreson
        @date: 20-Aug-2022
        @description: Returns Milestone Templates -- without Versions -- for a specific RT.
    **/    
    public static List<Milestone_Template__c> getMilestoneTemplatesByRecordTypeWithoutVersions(String parentSObjectType, Id recordTypeId) {
        return [SELECT Active__c, Completed_by_Stage__c, Default_Milestone_Status_on_Creation__c,
                    Default_Owner_on_Creation_18__c, Default_Sort_Order__c, Id,
                    Milestone_Creation_Type__c, Milestone_Record_Type_ID_18__c, Milestone_Type__c, Name,
                    Parent_Object_API_Name__c, Parent_Object_Record_Type_ID_18__c, Reviewed_by_Stage__c,
                    Stage_Completed_Sort_Order__c, Stage_Reviewed_Sort_Order__c
                FROM Milestone_Template__c
                WHERE Parent_Object_API_Name__c = :parentSObjectType
                AND Parent_Object_Record_Type_ID_18__c = :recordTypeId
                AND Active__c = true
                ORDER BY Default_Sort_Order__c];  
    }

    /**
        @author: Dan Thoreson
        @date: 20-Aug-2022
        @description: Retrieves a list of all the Milestone Versions -- and their ≈child Milestone Templates -- for a given RT.
    **/
    public static List<Milestone_Template_Version__c> getVersionsByRecordType(Id recordTypeId) {
        return [SELECT Id, Current_Latest_Version__c, End_Time__c, Record_Type_Id__c, Start_Time__c, Version_Number__c,
                    (SELECT Active__c, Completed_by_Stage__c, Default_Milestone_Status_on_Creation__c,
                            Default_Owner_on_Creation_18__c, Default_Sort_Order__c, Id,
                            Milestone_Creation_Type__c, Milestone_Record_Type_ID_18__c, Milestone_Type__c, Name,
                            Parent_Object_API_Name__c, Parent_Object_Record_Type_ID_18__c, Reviewed_by_Stage__c,
                            Stage_Completed_Sort_Order__c, Stage_Reviewed_Sort_Order__c
                    FROM Milestone_Templates__r 
                    WHERE Active__c = true 
                    ORDER BY Default_Sort_Order__c)
                FROM Milestone_Template_Version__c
                WHERE Record_Type_Id__c = :recordTypeId
                ORDER BY Version_Number__c];
    }

    /**
     * Converts a List of SObjects to a Map of Lists keyed by the given field.
     *
     * @param sobjects A List of SObjects
     * @param keyField The field to use as the key
     *
     * @return A Map of Lists keyed by the given key
     */
    private static Map<Id, List<SObject>> listToMappedList(List<SObject> sobjects, String keyField) {
        Map<Id, List<SObject>> sobjectMap = new Map<Id, List<SObject>>();
        for (SObject sobj : sobjects) {
            Id key = (Id) sobj.get(keyField);
            if (sobjectMap.containsKey(key)) {
                sobjectMap.get(key).add(sobj);
            } else {
                sobjectMap.put(key, new List<SObject> { sobj });
            }
        }

        return sobjectMap;
    }
}