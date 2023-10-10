/**
 * @description Unit Tests for the CasesSelector
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
@IsTest
private class CasesSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheCaseSObject() {
        SObjectType actualType = new CasesSelector().getSObjectType();
        System.assertEquals(
            Case.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Case.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Case.Id,
            Case.CaseNumber,
            Case.Status,
            Case.Subject,
            Case.AccountId,
            Case.ParentId,
            Case.RecordTypeId,
            Case.Opportunity_Name__c
        };

        SObjectField[] actualTokens = new CasesSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Case[] records = TDdCaseFactory.createCaseRecords(3, getActiveCaseRecordtypeName());
        insert records;

        // Act
        Map<Id,Case> testRecords = new Map<Id,Case>(new CasesSelector().selectById(new Set<Id>{
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
        Case[] records = TDdCaseFactory.createCaseRecords(1, getActiveCaseRecordtypeName());
        insert records;

        // Act
        Map<Id,Case> testRecords = new Map<Id,Case>(new CasesSelector().selectById(new Set<Id>{
            Fake.generateId(Case.class),
            Fake.generateId(Case.class)
        }));

        // Assert
        System.assert(testRecords.isEmpty());
    }

    @IsTest
    static void testSelectByIdWithAdditionalfields() {
        // Arrange
        List<Case> records = TDdCaseFactory.createCaseRecords(1, getActiveCaseRecordtypeName());
        insert records;

        // Act
        List<Case> testRecords = new CasesSelector().selectById(new Set<Id>{
            records[0].Id
        }, new Set<String>{'DispatchRQResponse__c'});

        // Assert
        System.assert(!testRecords.isEmpty(), 'No cases found');

        Boolean exceptionFound = false;
        if(testRecords.size() > 0){
            try {
                String dispatchResponse = testRecords[0].DispatchRQResponse__c;
            } catch (Exception ex) {
                exceptionFound = true;
            }
        }
        System.assert(!exceptionFound, 'No exception should occur');
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
}