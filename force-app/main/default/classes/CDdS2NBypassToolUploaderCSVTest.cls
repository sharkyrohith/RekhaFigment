@IsTest
public with sharing class CDdS2NBypassToolUploaderCSVTest {

    public final static String NIMDA_FIELDS_TEST_STR = '[ { "apiType":"String", "displayType":"Integer", "displayName":"Custom Delivery Fee", "property":"custom_delivery_fee" }, { "apiType":"Boolean", "displayType":"Boolean", "displayName":"Offers Delivery", "property":"offers_delivery" }, { "apiType":"String", "displayType":"String", "displayName":"Experience", "property":"experience" }, { "apiType":"Boolean", "displayType":"Boolean", "displayName":"Is consumer subscription eligible", "property":"is_consumer_subscription_eligible" }, { "apiType":"String", "displayType":"Boolean", "displayName":"Fulfills Own Deliveries", "property":"fulfills_own_deliveries" }, { "apiType":"String", "displayType":"Percent", "displayName":"Service Rate", "property":"service_rate" }, { "apiType":"String", "displayType":"Integer", "displayName":"Delivery Radius", "property":"delivery_radius" }, { "apiType":"String", "displayType":"String", "displayName":"Offers Pickup", "property":"offers_pickup" }, { "apiType":"String", "displayType":"String", "displayName":"Store Id", "property":"id" }, { "apiType":"String", "displayType":"Currency", "displayName":"Flat Commission Fee", "property":"flat_commission_fee" }, { "apiType":"String", "displayType":"Percent", "displayName":"Reduced Pickup Commission Rate", "property":"reduced_pickup_commission_rate" }, { "apiType":"String", "displayType":"Currency", "displayName":"Weekly Printer Fee", "property":"weekly_printer_subscription_fee" }, { "apiType":"Boolean", "displayType":"Boolean", "displayName":"Is Partner", "property":"is_partner" }, { "apiType":"String", "displayType":"Currency", "displayName":"Weekly Tablet Fee", "property":"weekly_tablet_subscription_fee" }, { "apiType":"String", "displayType":"Percent", "displayName":"Pickup Commission Rate", "property":"pickup_commission_rate" }, { "apiType":"String", "displayType":"Percent", "displayName":"Inflation Rate", "property":"inflation_rate" }, { "apiType":"String", "displayType":"Percent", "displayName":"Commission Rate", "property":"commission_rate" }, { "apiType":"String", "displayType":"Percent", "displayName":"Subscription Commission Rate", "property":"subscription_commission_rate" }, { "apiType":"String", "displayType":"Percent", "displayName":"Reduced Commission Rate", "property":"reduced_commission_rate" }, { "apiType":"String", "displayType":"Integer", "displayName":"Inflation Round Unit", "property":"inflation_rounding_unit" }, { "apiType":"String", "displayType":"Currency", "displayName":"Subscription Flat Fee", "property":"subscription_flat_fee" } ]'; 

    @TestSetup
    static void setup(){
        Account testAccount = new Account();
        //testAccount.Name = 'John Doe';
        testAccount.LastName = 'Doe';
        testAccount.FirstName = 'John';
        testAccount.Phone = '855-973-1040';
        testAccount.Restaurant_ID__c = '123456789';
        insert testAccount;
    }

    @IsTest
    public static void testValidCSV(){
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
        String csv = 'accountId,store_id,commission_rate\n';
        csv += acct.Id + ',' + acct.Restaurant_ID__c + ',10';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV bypassUploader = new CDdS2NBypassToolUploaderCSV(csv);
        Test.stopTest();
        
        System.assertEquals(true, bypassUploader.isImportable);
    }

    @IsTest
    public static void testFullValidCSV(){
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
        String csv = 'store_id,accountId,offers_delivery,service_rate,offers_pickup,flat_commission_fee,reduced_pickup_commission_rate,weekly_printer_subscription_fee,is_partner,weekly_tablet_subscription_fee,pickup_commission_rate,inflation_rate,commission_rate,subscription_commission_rate,reduced_commission_rate,inflation_rounding_unit,subscription_flat_fee\n';
        csv += acct.Restaurant_ID__c + ',' + acct.Id + ',true,9,true,4,5,6,true,7,8,9,10,11,12,13,14';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV bypassUploader = new CDdS2NBypassToolUploaderCSV(csv);
        Test.stopTest();
        
        System.assertEquals(true, bypassUploader.isImportable);
    }
    
    @IsTest
    public static void testNotValidCSV(){
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
        String csv = 'accountId,store_id,commission_rate\n';
        csv += acct.Id + ',1234,10';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV bypassUploader = new CDdS2NBypassToolUploaderCSV(csv);
        Test.stopTest();
        
        System.assertEquals(false, bypassUploader.isImportable);
    }

    @IsTest
    public static void testStandardizedId() {
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];
        String accountId = String.valueOf(acct.Id).substring(0, 15);

        String csv = 'accountId,store_id,commission_rate\n';
        csv += accountId + ',' + acct.Restaurant_ID__c + ',10';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV bypassUploader = new CDdS2NBypassToolUploaderCSV(csv);
        Test.stopTest();

        System.assertEquals(true, bypassUploader.isImportable);
    }
    
    @IsTest
    public static void testNullValues() {
        Account acct = [SELECT Id, Restaurant_ID__c FROM Account LIMIT 1];

        String csv = 'accountId,store_id,commission_rate\n';
        csv += acct.Id + ',' + acct.Restaurant_ID__c + ',';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV bypassUploader = new CDdS2NBypassToolUploaderCSV(csv);
        Test.stopTest();

        System.assertEquals(true, bypassUploader.isImportable);
    }
    
    @IsTest
    public static void testIsNumeric() {
		String strPercent = '5';
        String strDouble = '1.4';
        String strInteger = '4';
        String strCurrency = '1.59';
        
        Test.startTest();
        CDdS2NBypassToolUploaderCSV.Cell cell = new CDdS2NBypassToolUploaderCSV.Cell('cell');
        Test.stopTest();

        System.assertEquals(true, cell.isNumeric(strPercent));
        System.assertEquals(true, cell.isNumeric(strDouble));
        System.assertEquals(true, cell.isNumeric(strInteger));
        System.assertEquals(true, cell.isNumeric(strCurrency));
    }
}