/**
* @author Ed
* @date 2021-06
* @description BZAP-11027, 11032 Test class for Vertical Categories
*/
@isTest
public class CDdVerticalCategoryHelperTest {
    
    
    
    public CDdVerticalCategoryHelperTest() { }

    @testSetup
    static void setup() {
        Id categoryRecordTypeId = Schema.SObjectType.Vertical_Category__c.getRecordTypeInfosByDeveloperName().get('Category').getRecordTypeId();
        Id subCategoryRecordTypeId = Schema.SObjectType.Vertical_Category__c.getRecordTypeInfosByDeveloperName().get('Sub_Category').getRecordTypeId();

        // Insert parent categories
        List<Vertical_Category__c> parentCategoryList = new List<Vertical_Category__c>();
        Vertical_Category__c parentCategory1 = new Vertical_Category__c(Name = 'Alcohol', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory2 = new Vertical_Category__c(Name = 'Prepared Food & Drink (Rx)', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory3 = new Vertical_Category__c(Name = 'Grocery', RecordTypeId = categoryRecordTypeId);
        Vertical_Category__c parentCategory4 = new Vertical_Category__c(Name = 'Flowers', RecordTypeId = categoryRecordTypeId);
        parentCategoryList.add(parentCategory1);
        parentCategoryList.add(parentCategory2);
        parentCategoryList.add(parentCategory3);
        parentCategoryList.add(parentCategory4);
        insert parentCategoryList;


        // Insert subcategories
        List<Vertical_Category__c> subCategoryList = new List<Vertical_Category__c>();
        Vertical_Category__c subCategory1 = new Vertical_Category__c(Name = 'Alcohol-Lite', Parent_Category__c = parentCategory1.Id, RecordTypeId = subCategoryRecordTypeId);
        Vertical_Category__c subCategory2 = new Vertical_Category__c(Name = 'Bakery', Parent_Category__c = parentCategory2.Id, RecordTypeId = subCategoryRecordTypeId);
        Vertical_Category__c subCategory3 = new Vertical_Category__c(Name = 'Ice Cream', Parent_Category__c = parentCategory2.Id, RecordTypeId = subCategoryRecordTypeId);
        Vertical_Category__c subCategory4 = new Vertical_Category__c(Name = 'Drinks', Parent_Category__c = parentCategory2.Id, RecordTypeId = subCategoryRecordTypeId);
        Vertical_Category__c subCategory5 = new Vertical_Category__c(Name = 'Sub Flowers', Parent_Category__c = parentCategory4.Id, RecordTypeId = subCategoryRecordTypeId);
        subCategoryList.add(subCategory1);
        subCategoryList.add(subCategory2);
        subCategoryList.add(subCategory3);
        subCategoryList.add(subCategory4);
        subCategoryList.add(subCategory5);
        insert subCategoryList;

        // Insert custom setting.. Maybe not need 
        
        // insert account
        List<Account> testAccounts = TDdAccountFactory.createAccounts('Child Account', 2);
        testAccounts[0].Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        testAccounts[0].Primary_Merchant_Category__c = 'Alcohol';
        testAccounts[1].Merchant_Categories__c = 'Alcohol';
        testAccounts[1].Primary_Merchant_Category__c = 'Alcohol';
        insert testAccounts;

        // this flag prevents trigger recursion, but needs to be reset during test set up before next insert
        CDdVerticalCategoryHelper.handleMerchantCategoriesFlag = false;

        // insert lead
        Lead testLead = TDdLeadFactory.createLeads('Test Lead ', 1, 'Master Lead', false)[0];
        testLead.Merchant_Categories__c = 'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        testLead.Primary_Merchant_Category__c = 'Alcohol';
        insert testLead;
    }

    @isTest
    public static void updateAccountPrimaryCategory() {
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];

        Test.startTest();
        testAcct.Primary_Merchant_Category__c = 'Prepared Food & Drink (Rx)';
        update testAcct;
        Test.stopTest();

        Vertical_Category__c foodDrinkVertCat = [SELECT ID FROM Vertical_Category__c WHERE Name = 'Prepared Food & Drink (Rx)' LIMIT 1];
        Merchant_Category__c primaryMxCat = [SELECT ID, Primary__c FROM Merchant_Category__c WHERE Account__c = :testAcct.Id AND Vertical_Category__c = :foodDrinkVertCat.Id LIMIT 1];
        System.assertEquals(true, primaryMxCat.Primary__c);
    }

    @isTest
    public static void updateAccountVerticalCategories() {
        //'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery'
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];

        Test.startTest();
        testAcct.Merchant_Categories__c = 'Flowers / Sub Flowers ; Grocery ; Prepared Food & Drink (Rx) / Ice Cream';
        testAcct.Primary_Merchant_Category__c = 'Grocery';
        update testAcct;
        Test.stopTest();

        Id newAcctId = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Grocery' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :newAcctId].size();
        System.assertEquals(5, newMxCatCount);
    }

    @isTest
    public static void updateLeadVerticalCategories() {
        Lead testLead = [SELECT Id,Merchant_Categories__c,Primary_Merchant_Category__c  FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];

        Test.startTest();
        testLead.Merchant_Categories__c = 'Flowers ; Grocery ; Prepared Food & Drink (Rx) / Ice Cream';
        testLead.Primary_Merchant_Category__c = 'Grocery';
        update testLead;
        Test.stopTest();

        Id newLeadId = [SELECT Id FROM Lead WHERE Primary_Merchant_Category__c = 'Grocery' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Lead__c = :newLeadId].size();
        System.assertEquals(4, newMxCatCount);
    }

    @isTest
    public static void deleteAccountVerticalCategories() {
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        
        Test.startTest();
        testAcct.Merchant_Categories__c = '';
        testAcct.Primary_Merchant_Category__c = '';
        update testAcct;  
        Test.stopTest();

        Account newAcct = [SELECT Id, Merchant_Categories__c FROM Account LIMIT 1];
        System.assertEquals(null, newAcct.Merchant_Categories__c);
    }    

    @isTest
    public static void deleteLeadVerticalCategories() {
        Lead testLead = [SELECT Id FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        
        Test.startTest();
        testLead.Merchant_Categories__c = '';
        testLead.Primary_Merchant_Category__c = '';
        update testLead;
        Test.stopTest();

        Lead newLead = [SELECT Id, Merchant_Categories__c FROM Lead LIMIT 1];
        System.assertEquals(null, newLead.Merchant_Categories__c);
    }

    @isTest
    public static void insertMerchantCategoryForAccount() {
        //'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        Vertical_Category__c iceCreamVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Ice Cream' LIMIT 1];
        Vertical_Category__c flowerVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Flowers' LIMIT 1];
        Vertical_Category__c subFlowerVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Sub Flowers' LIMIT 1];
        List<Merchant_Category__c> testMerchantCategories = new List<Merchant_Category__c>();

        Test.startTest();
        testMerchantCategories.add(new Merchant_Category__c(Account__c = testAcct.Id, Vertical_Category__c=iceCreamVertCategory.Id));
        testMerchantCategories.add(new Merchant_Category__c(Account__c = testAcct.Id, Vertical_Category__c=flowerVertCategory.Id));
        testMerchantCategories.add(new Merchant_Category__c(Account__c = testAcct.Id, Vertical_Category__c=subFlowerVertCategory.Id));
        insert testMerchantCategories;
        Test.stopTest();

        Id newAcctId = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :newAcctId].size();
        System.assertEquals(8, newMxCatCount);
    }

    @isTest
    public static void insertMerchantCategoryForLead() {
        // 'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery'
        Lead testLead = [SELECT Id FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        Vertical_Category__c iceCreamVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Ice Cream' LIMIT 1];
        Vertical_Category__c flowerVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Flowers' LIMIT 1];
        List<Merchant_Category__c> testMerchantCategories = new List<Merchant_Category__c>();

        Test.startTest();
        testMerchantCategories.add(new Merchant_Category__c(Lead__c = testLead.Id, Vertical_Category__c=iceCreamVertCategory.Id));
        testMerchantCategories.add(new Merchant_Category__c(Lead__c = testLead.Id, Vertical_Category__c=flowerVertCategory.Id));
        insert testMerchantCategories;
        Test.stopTest();

        Id newLeadId = [SELECT Id FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Lead__c = :newLeadId].size();
        System.assertEquals(7, newMxCatCount);
    }

    @isTest
    public static void deleteMerchantCategoryParentForAccount() {
        //'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        List<Vertical_Category__c> vertCategories = [SELECT Id FROM Vertical_Category__c WHERE Name in ('Prepared Food & Drink (Rx)', 'Grocery')];

        Test.startTest();
        List<Merchant_Category__c> deleteMxCats = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :testAcct.Id AND Vertical_Category__c in :vertCategories];
        delete deleteMxCats;
        Test.stopTest();

        Id newAcctId = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :newAcctId].size();
        System.assertEquals(2, newMxCatCount);
    }

    @isTest
    public static void deleteMerchantCategoryChildForAccount() {
        //'Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        Vertical_Category__c vertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Bakery' LIMIT 1];

        Test.startTest();
        List<Merchant_Category__c> deleteMxCats = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :testAcct.Id AND Vertical_Category__c = :vertCategory.Id];
        delete deleteMxCats;
        Test.stopTest();

        Id newAcctId = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :newAcctId].size();
        System.assertEquals(4, newMxCatCount);
    }

    @isTest
    public static void deleteVerticalCategory() {
        Test.startTest();
        Vertical_Category__c flowerVertCategory = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Flowers' LIMIT 1];
        delete flowerVertCategory;
        Test.stopTest();

        Integer newVertCatCount = [SELECT Id FROM Vertical_Category__c WHERE Name = 'Flowers'].size();
        System.assertEquals(0, newVertCatCount);
    }

    @isTest
    public static void mergeAccountVerticalCategories() {
        //Alcohol / Alcohol-Lite ; Grocery ; Prepared Food & Drink (Rx) / Bakery';
        List<Account> mergeAccounts = TDdAccountFactory.createAccounts('Merge Accounts', 2);
        mergeAccounts[0].Merchant_Categories__c = 'Prepared Food & Drink (Rx) / Bakery / Drinks';
        mergeAccounts[0].Primary_Merchant_Category__c = 'Prepared Food & Drink (Rx)';
        mergeAccounts[1].Merchant_Categories__c = 'Flowers / Sub Flowers';
        mergeAccounts[1].Primary_Merchant_Category__c = 'Flowers';
        insert mergeAccounts;
        
        Test.startTest();
        Account testAcct = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        Database.merge(testAcct, mergeAccounts);
        Test.stopTest();

        Account afterMerge = [SELECT Id,Merchant_Categories__c FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        System.assertEquals('Alcohol / Alcohol-Lite ; Flowers / Sub Flowers ; Grocery ; Prepared Food & Drink (Rx) / Bakery / Drinks', afterMerge.Merchant_Categories__c);
        
        Id newAcctId = [SELECT Id FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1].Id;
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Account__c = :afterMerge.Id].size();
        // TODO queueable has to be tested directly
        // System.assertEquals(8, newMxCatCount);
    }

    @isTest
    public static void mergeLeadVerticalCategories() {
        // using factory again causes issues, for unclear reason
        Lead mergeLead = new Lead (LastName = 'Merge Lead',
                                        Company = 'Merge Lead', 
                                        Phone = '(123) 234-2359', 
                                        Street = '125 Mulberry Ln',
                                        City = 'South San Francisco',
                                        State = 'CA',
                                        PostalCode = '94108', 
                                        CountryCode = 'US',
                                        Validation_Bypass__c = true);

        mergeLead.Merchant_Categories__c = 'Prepared Food & Drink (Rx) / Drinks ; Flowers / Sub Flowers';
        mergeLead.Primary_Merchant_Category__c = 'Prepared Food & Drink (Rx)';
        mergeLead.Phone = '(123) 234-2355';
        insert mergeLead;

        Test.startTest();
        Lead testLead = [SELECT Id FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        Database.merge(testLead, mergeLead, false);
        Test.stopTest();

        Lead afterMerge = [SELECT Id,Merchant_Categories__c FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
        System.assertEquals('Alcohol / Alcohol-Lite ; Flowers / Sub Flowers ; Grocery ; Prepared Food & Drink (Rx) / Bakery / Drinks', afterMerge.Merchant_Categories__c);
        
        Integer newMxCatCount = [SELECT Id FROM Merchant_Category__c WHERE Lead__c = :afterMerge.Id].size();
        // TODO queueable has to be tested directly
        // System.assertEquals(8, newMxCatCount);
    }

    @isTest
    public static void updateHubspotMerchantCategoriesTest(){
        
        User testRunUser = TDdAccountFactory.createUsers(1)[0];
        testRunUser.FirstName = 'Hubspot';
        testRunUser.LastName = 'Integration User';
        insert testRunUser;
       
        System.runAs(testRunUser){
            Account testAccount = [SELECT Id, Merchant_Categories__c FROM Account WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1];
            
            Vertical_Category_Trigger_Setting__c vertCatSetting = new Vertical_Category_Trigger_Setting__c();
            vertCatSetting.Run_Update_Merchant_Categories_method__c = true;
            vertCatSetting.SetupOwnerId = testRunUser.Id;
            insert vertCatSetting;
            
            Test.startTest();
            testAccount.Primary_Merchant_Category__c = 'Flowers';
            update testAccount;
            Test.stopTest();
        }
        
        Account newAcct = [SELECT Id, Merchant_Categories__c FROM Account WHERE Primary_Merchant_Category__c = 'Flowers' LIMIT 1];
        
        System.assertEquals('Alcohol / Alcohol-Lite ; Flowers ; Grocery ; Prepared Food & Drink (Rx) / Bakery', newAcct.Merchant_Categories__c);
    }

    @isTest
    public static void syncPrimaryMerchantCategoryFieldsTestInsert(){
        Account testAccount = TDdAccountFactory.createAccount();
        testAccount.Primary_Merchant_Category__c = 'Flowers';
        testAccount.Merchant_Categories__c = 'Flowers';
        
        Vertical_Category_Trigger_Setting__c vertCatSetting = new Vertical_Category_Trigger_Setting__c();
        vertCatSetting.Run_Sync_Primary_Merchant_Cat_Fields__c = true;
        insert vertCatSetting;

        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        Account newAcct = [SELECT Id, Primary_Merchant_Categories__c FROM Account WHERE Primary_Merchant_Category__c = 'Flowers' LIMIT 1];
        
        System.assertEquals(testAccount.Primary_Merchant_Category__c, newAcct.Primary_Merchant_Categories__c);
    }
    
    @isTest
    public static void syncPrimaryMerchantCategoryFieldsTestUpdate(){
        
        Vertical_Category_Trigger_Setting__c vertCatSetting = new Vertical_Category_Trigger_Setting__c();
        vertCatSetting.Run_Sync_Primary_Merchant_Cat_Fields__c = true;
        insert vertCatSetting;
        
        List<Account> testAccounts = new List<Account>([SELECT Id, Merchant_Categories__c FROM Account LIMIT 2]);
        testAccounts[0].Primary_Merchant_Category__c = 'Flowers';
        testAccounts[0].Merchant_Categories__c = 'Flowers';
		testAccounts[1].Primary_Merchant_Categories__c = 'Flowers';
        testAccounts[1].Merchant_Categories__c = 'Flowers';

        Lead testLead = [SELECT Id, Merchant_Categories__c FROM Lead WHERE Primary_Merchant_Category__c = 'Alcohol' LIMIT 1][0];
        testLead.Primary_Merchant_Category__c = 'Flowers';
        testLead.Merchant_Categories__c = 'Flowers';
        
        Test.startTest();
        update testAccounts;
        update testLead;
        Test.stopTest();
        
        List<Account> newAccts = [SELECT Id, Primary_Merchant_Categories__c, Primary_Merchant_Category__c FROM Account LIMIT 2];
        Lead newlead = [SELECT Id, Primary_Merchant_Categories__c FROM Lead WHERE Primary_Merchant_Categories__c = 'Flowers' LIMIT 1]; 
        
        System.assertEquals(testAccounts[0].Primary_Merchant_Category__c, newAccts[0].Primary_Merchant_Categories__c);
        System.assertEquals(testAccounts[1].Primary_Merchant_Categories__c, newAccts[1].Primary_Merchant_Category__c);
        System.assertEquals(testLead.Primary_Merchant_Category__c, newlead.Primary_Merchant_Categories__c);
    }
}