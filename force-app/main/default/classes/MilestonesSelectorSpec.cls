/**
 * @description Unit Tests for the MilestonesSelector
 *
 * @author Krishna Sanisetty
 * @date 10/07/2022
 */
@isTest
private class MilestonesSelectorSpec {

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheMilestoneSObject() {
        SObjectType actualType = new MilestonesSelector().getSObjectType();
        System.assertEquals(
            Milestone__c.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Case.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Milestone__c.Id,
            Milestone__c.Case__c,
            Milestone__c.Status__c
        };

        SObjectField[] actualTokens = new MilestonesSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }
    @IsTest
    static void testWhenselectByCaseIdAndRecordTypeNameThenItShouldReturnRecordsWithTheGivenIds() {
        Case[] cases = TDdCaseFactory.createCaseRecords(1, getActiveCaseRecordtypeName());
        insert cases;

        string status = 'Not Started';
        List<RecordType> activeMilestoneRecordTypeList = getActiveMilestoneRecordType();
        List<Milestone__c> milestonesList = new List<Milestone__c>();
        for(RecordType rt: activeMilestoneRecordTypeList){
            Milestone__c milestone = new Milestone__c();
            milestone.recordtypeid = rt.Id;
            milestone.status__c = status;
            milestone.case__c = cases[0].Id;
            milestonesList.add(milestone);
        }

        insert milestonesList;

        List<Milestone__c> milestones = MilestonesSelector.newInstance().selectByCaseIdAndRecordTypeName(new Set<Id>{cases[0].Id}, new Set<String>{activeMilestoneRecordTypeList[0].Name});
        System.assert(milestones.size() == 1);
        System.assert(milestones[0].RecordType.Name == activeMilestoneRecordTypeList[0].Name);
    }

    @IsTest
    static void testWhenQueryingMilestonesByDeveloperNameShouldReturnExpectedRecords() {
        Case[] cases = TDdCaseFactory.createCaseRecords(1, CDdSupportConstants.RECORDTYPE_NAME_MARKETPLACE_ONBOARDING);
        insert cases;
        
        List<RecordType> milestoneRecordTypes = getActiveMilestoneRecordType();
        List<Milestone__c> milestonesToInsert = new List<Milestone__c>();
        
        for(RecordType thisRecordType : milestoneRecordTypes) {
            Milestone__c newMilestone = new Milestone__c(Case__c = cases[0].Id);
            newMilestone.RecordTypeId = thisRecordType.Id;
            newMilestone.Status__c = 'Not Started';
            milestonesToInsert.add(newMilestone);
        }

        insert milestonesToInsert;

        List<Milestone__c> milestones = MilestonesSelector.newInstance().selectByCaseIdAndRecordTypeDeveloperName(new Set<Id>{cases[0].Id}, new Set<String>{milestoneRecordTypes[0].DeveloperName});
        System.assert(!milestones.isEmpty(), 'Milestones should be returned for the given Case');
    }

    static String getActiveCaseRecordtypeName() {
        RecordType caseRecordType = [
            SELECT Name
            FROM RecordType
            WHERE SobjectType = 'Case'
            AND IsActive = TRUE
            LIMIT 1
        ];
        return caseRecordType?.Name;
    }

    static List<RecordType> getActiveMilestoneRecordType() {
        List<RecordType> milestoneRecordTypeList = [
            SELECT Id, Name, DeveloperName
            FROM RecordType
            WHERE SobjectType = 'Milestone__c'
            AND IsActive = TRUE
            LIMIT 2
        ];
        return milestoneRecordTypeList;
    }
}