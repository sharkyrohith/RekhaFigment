/**
* @ author Abhijeet
* @date 2021-07
* @description Test class for DDCopyMerge 
* This class uses the setup method to create the seed data required for all relevant test cases
*/
@isTest
public class CDdCopyMergeTest {
    
    @TestSetup
    static void setup() {
        List<Account> testAccounts = TDdAccountFactory.createAccounts('TestDDAccount', 2);
        testAccounts[1].Bank_Account_Number_Encrypted__c  = 'test000111';
        insert testAccounts;
    }

    @isTest
    static void testMergeAccount() {
        List<Account> testAccounts = [ SELECT Id, Name, Bank_Account_Number_Encrypted__c, Copy_Account_Info__c, Source_Account__c, Field_Set__c FROM Account ];
        
        testAccounts[0].Copy_Account_Info__c = true;
        testAccounts[0].Source_Account__c = testAccounts[1].Id;
        testAccounts[0].Field_Set__c = 'Banking Information';
        Test.startTest();
        update testAccounts[0];
        Test.stopTest();
        
        List<Account> accountsWithBankAccountNumber = [SELECT Id, Name, Bank_Account_Number_Encrypted__c ,Copy_Account_Info__c FROM Account];
        if(accountsWithBankAccountNumber.size()==2){
            
            system.assertEquals(accountsWithBankAccountNumber[0].Bank_Account_Number_Encrypted__c,accountsWithBankAccountNumber[1].Bank_Account_Number_Encrypted__c, 'Banking info not copied');
            
        }
        //System.assertEquals(2, accountsWithBankAccountNumber.size(), 'Sensitive data is not copied from source record to target record');
        for(Account acc: accountsWithBankAccountNumber) {
            if(acc.Id == testAccounts[0].Id) {
                System.assertEquals(false, acc.Copy_Account_Info__c, 'Copy Account Info flag must be reset to false');
            }
        }
    }

}