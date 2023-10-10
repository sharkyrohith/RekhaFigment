/**
 * @description Unit Tests for the ContactsSelector
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
@IsTest
private class ContactsSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheContactSObject() {
        SObjectType actualType = new ContactsSelector().getSObjectType();
        System.assertEquals(
            Contact.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Contact.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Contact.Id,
            Contact.FirstName,
            Contact.LastName
        };

        SObjectField[] actualTokens = new ContactsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenSelectedByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Account objAccount = TDdAccountFactory.createAccount();
        insert objAccount;
        Contact[] records = new Contact[]{
            VTestUtil.createContact('first', 'last', objAccount),
            VTestUtil.createContact('first', 'last', objAccount),
            VTestUtil.createContact('first', 'last', objAccount)
        };
        insert records;

        // Act
        Map<Id,Contact> testRecords = new Map<Id,Contact>(new ContactsSelector().selectById(new Set<Id>{
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
        Account objAccount = TDdAccountFactory.createAccount();
        insert objAccount;
        VTestUtil.createContact('first', 'last', objAccount);

        // Act
        Map<Id,Contact> testRecords = new Map<Id,Contact>(new ContactsSelector().selectById(new Set<Id>{
            Fake.generateId(Contact.class),
            Fake.generateId(Contact.class)
        }));

        // Assert
        System.assert(testRecords.isEmpty());
    }
}