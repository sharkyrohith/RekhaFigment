/**
 * @description Unit Tests for the AccountsSelector
 *
 * @author Scott McClung
 * @date 2022/08/16
 */
@IsTest
private class AccountsSelectorSpec {
    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsFromTheAccountSObject() {
        SObjectType actualType = new AccountsSelector().getSObjectType();
        System.assertEquals(
            Account.SObjectType,
            actualType,
            'Received an unexpected SObject token.  Expecting Account.SObjectType and received: ' + actualType);
    }

    @IsTest
    static void testWhenQueriesAreExecutedThenItShouldReturnRecordsWithTheExpectedFields() {
        SObjectField[] expectedTokens = new SObjectField[]{
            Account.Id,
            Account.Name,
            Account.ParentId,
            Account.ADR_Owner_Actual__c,
            Account.OwnerId,
            Account.Restaurant_ID__c
        };

        SObjectField[] actualTokens = new AccountsSelector().getSObjectFieldList();
        System.assertEquals(
            expectedTokens,
            actualTokens,
            'Received an unexpected list of SObjectField tokens.  Expected: ' + expectedTokens + ' Received: ' + actualTokens
        );
    }

    @IsTest
    static void testWhenCallingSelectByIdThenItShouldReturnRecordsWithTheGivenIds() {
        // Arrange
        Account[] records = TDdAccountFactory.createAccounts('TestAccounts', 3);
        insert records;

        // Act
        Map<Id,Account> testRecords = new Map<Id,Account>(new AccountsSelector().selectById(new Set<Id>{
            records[0].Id,
            records[1].Id
        }));

        // Assert
        System.assert(testRecords.keySet().contains(records[0].Id));
        System.assert(testRecords.keySet().contains(records[1].Id));
    }

    @IsTest
    static void testWhenCallingSelectByIdThenItShouldNotReturnRecordsOutsideOfTheGivenIds() {
        // Arrange
        Account[] records = TDdAccountFactory.createAccounts('TestAccounts', 2);
        insert records;

        // Act
        Map<Id,Account> testRecords = new Map<Id,Account>(new AccountsSelector().selectById(new Set<Id>{
            Fake.generateId(Account.class),
            Fake.generateId(Account.class)
        }));

        // Assert
        System.assert(testRecords.isEmpty());
    }


    @IsTest
    static void testWhenCallingselectAccountsByBusinessIdThenItShouldNotReturnRecordsOutsideOfTheBusinessIds() {
        // Arrange
        Account[] records = TDdAccountFactory.createAccounts('TestAccounts', 2);
        records[0].Business_ID__c = 1234;
        insert records;
        Set<Decimal> businessIds = new Set<Decimal>{1234};
        List<Account> lstReturnedAccs = AccountsSelector.newInstance().selectAccountsByBusinessId(businessIds);
        // Assert
        System.assertEquals(1, lstReturnedAccs.size(), 'Should return one account with that business Id');
    }

    @IsTest
    static void testWhenCallingQueryLocatorSelectAccountsByBusinessIdThenItShouldNotReturnRecordsOutsideOfTheBusinessIds() {
        // Arrange
        Account[] records = TDdAccountFactory.createAccounts('TestAccounts', 2);
        records[0].Business_ID__c = 1234;
        insert records;
        Set<Decimal> businessIds = new Set<Decimal>{1234};
        Database.QueryLocator queryLocator = AccountsSelector.newInstance().queryLocatorSelectAccountsByBusinessId(businessIds);
        // Assert
        System.assertEquals(true, queryLocator!=null, 'Should return valid queryLocator');
    }
}