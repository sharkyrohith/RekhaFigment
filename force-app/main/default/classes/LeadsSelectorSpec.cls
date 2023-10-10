/**
 * @description Unit Tests for the LeadsSelector
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
@IsTest
private class LeadsSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheLeadSObject() {
        SObjectType actualType = new LeadsSelector().getSObjectType();
        System.assertEquals(
            Lead.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Lead.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Lead.Id,
            Lead.FirstName,
            Lead.LastName,
            Lead.Street,
            Lead.City,
            Lead.State,
            Lead.Country,
            Lead.PostalCode
        };

        SObjectField[] actualTokens = new LeadsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Lead[] records = TDdLeadFactory.createLeads('TestLeads', 3, false);
        insert records;

        // Act
        Map<Id,Lead> testRecords = new Map<Id,Lead>(new LeadsSelector().selectById(new Set<Id>{
            records[0].Id,
            records[1].Id
        }));

        // Assert
        System.assert(testRecords.keySet().contains(records[0].Id));
        System.assert(testRecords.keySet().contains(records[1].Id));
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        Lead[] records = TDdLeadFactory.createLeads('TestLeads', 2, false);
        insert records;

        // Act
        Map<Id,Lead> testRecords = new Map<Id,Lead>(new LeadsSelector().selectById(new Set<Id>{
            Fake.generateId(Lead.class),
            Fake.generateId(Lead.class)
        }));

        // Assert
        System.assert(testRecords.isEmpty());
    }

    @isTest
    static void testWhenSelectByCreatedFromContactThenItShouldReturnRecordsWithGivenIds() {
        // Arrange
        Account account = TDdAccountFactory.createAccount();
        insert account;

        Contact contact = TDdAccountFactory.createContacts(1, account.Id)[0];
        insert contact;

        Lead[] records = TDdLeadFactory.createLeads('TestLeads', 3, false);
        records[0].Created_from_Contact__c = contact.Id;
        records[1].Created_from_Contact__c = contact.Id;
        insert records;

        // Act
        Map<Id,Lead> testRecords = new Map<Id,Lead>(new LeadsSelector().selectLeadsByCreatedFromContact(new Set<Id>{
            contact.Id
        }));

        // Assert
        System.assert(testRecords.keySet().contains(records[0].Id));
        System.assert(testRecords.keySet().contains(records[1].Id));
    }
}