/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

public with sharing class CDdActivationChecklistController {
    @AuraEnabled
    public static List<Activation_Checklist__c> getChecklist(String caseId) {
        return [
                select
                        Id, Developer_Name__c, Name, Result__c, Status__c,
                        Original_Status__c, Time_to_Resolve__c, Resolved__c,
                        Date_Time_Ran__c, Target__c
                from Activation_Checklist__c
                where Case__c = :caseId
                order by Order__c
        ];
    }

    @AuraEnabled
    public static List<Activation_Checklist__c> validate(String caseId) {
        CDdActivationChecklist checklist = new CDdActivationChecklist(caseId);
        checklist.performChecks();
        return getChecklist(caseId);
    }

    @AuraEnabled
    public static List<Activation_Checklist__c> resolveItems(String caseId, List<Activation_Checklist__c> items) {
        update items;
        return getChecklist(caseId);
    }
}