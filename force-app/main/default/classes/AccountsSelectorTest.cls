/**
    @author: Dan Thoreson
    @date: 09-Nov-2022
    @description: Tests for the CasesSelector. Includes full tests with DML to determine the accuracy
                  of the data returned. Basic unit tests for the CasesSelector are in CasesSelectorSpec.
**/
@IsTest
private class AccountsSelectorTest {

    private static final Integer CHILD_ACCOUNTS_TO_CREATE = 1;
    private static final String RESTAURANT_ID = '5678';
    private static Id parentAccountId {get {
        if(parentAccountId == null) {
            parentAccountId = [SELECT Id FROM Account WHERE RecordTypeId = :CDdSchemaUtils.ACCOUNT_RT.parentAccountId() LIMIT 1].Id;
        }

        return parentAccountId;
    } set;}

    @TestSetup
    static void initData() {
        System.runAs(getTestRunUser()) {
            CDdCaseMilestoneTest.initializeTestSettings();

            List<Account> parentAccounts = TDdAccountFactory.createAccounts('Parent_Account_1', 1, 'Parent Account');
            insert parentAccounts;

            List<Account> childAccounts = TDdAccountFactory.createAccounts('Child_Account_1', CHILD_ACCOUNTS_TO_CREATE, 'Marketplace');

            for(Account thisAccount : childAccounts) {
                thisAccount.ParentId = parentAccounts[0].Id;
                thisAccount.Restaurant_ID__c = RESTAURANT_ID;
            }

            insert childAccounts;
        }
    }

    @IsTest
    static void testSelectAccountsForParent() {
        Test.startTest();
            List<Account> results = AccountsSelector.newInstance().selectAccountsForParent(parentAccountId);
        Test.stopTest();

        System.assertEquals(CHILD_ACCOUNTS_TO_CREATE, results.size());
    }
    @IsTest
    static void testSelectAccountsByStoreId() {
        Test.startTest();
            Set<String> resturentIds = new Set<String>{RESTAURANT_ID};
            List<Account> results = AccountsSelector.newInstance().selectAccountsByStoreId(resturentIds);
        Test.stopTest();

        System.assertEquals(CHILD_ACCOUNTS_TO_CREATE, results.size());
    }

    private static User getTestRunUser() {
        // References one of the methods to get test run user in Figment; most have the same requirements
        return CDdCaseMilestoneTest.getTestRunUser();
    }    
}