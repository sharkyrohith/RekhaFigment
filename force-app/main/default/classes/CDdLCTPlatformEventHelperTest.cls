/**
* @author Raghu Mandapaka
* @date 07-19-2021
* @description Test class for Handler for Live Chat Transcript Platform Event             
**/
@isTest
public class CDdLCTPlatformEventHelperTest {
    
    private Static map<string, Schema.RecordTypeInfo> accountRecTypeMap = Account.SobjectType.getDescribe().getRecordTypeInfosByName();
    public static final Id accRecordTypeId = accountRecTypeMap.get('Marketplace').getRecordTypeId();
    
    /**
    * @author Raghu Mandapaka
    * @description Test setup Method
    **/
    @testSetup
    static void testSetup() {
        List<Account> accList = CDdTestDataFactory.createSObjectList('Account',2,false);            
        for(Integer index=0; index <accList.size(); index++){                
            if(index == 0){
                accList[index].Name = 'Test Account 0';
                accList[index].phone = '2000393539';
                accList[index].BillingCountryCode = 'US';
                accList[index].BillingPostalCode = '95689';
                accList[index].BillingState = 'CA';
                accList[index].BillingCity = 'South San Francisco';
                accList[index].Bank_Account_Number_Encrypted__c = '123456780';
                accList[index].Bank_Routing_Number_Encrypted__c = '123456789';
                accList[index].EIN_Encrypted__c ='123456789';
                accList[index].RecordTypeId =accRecordTypeId;
                accList[index].Legal_Business_Name__c = 'test';  
                accList[index].BillingStreet = index + ' Mulberry Ln';                  
            }               
            else if(index == 1){
                accList[index].Name = 'Test Account 1';
                accList[index].phone = '2098393539';
                accList[index].BillingCountryCode = 'US';
                accList[index].BillingPostalCode = '95689';
                accList[index].BillingState = 'CA';
                accList[index].BillingCity = 'South San Francisco';
                accList[index].Bank_Account_Number_Encrypted__c = '123456780';
                accList[index].Bank_Routing_Number_Encrypted__c = '123456789';
                accList[index].EIN_Encrypted__c ='123456789';
                accList[index].RecordTypeId =accRecordTypeId;
                accList[index].Legal_Business_Name__c = 'test';  
                accList[index].BillingStreet = index + ' Mulberry Ln';
            }        
        }
        insert accList; 
    } 
    
    /**
    * @author Raghu Mandapaka
    * @description this method is to pass the LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD event
    **/
    @isTest
    public static void testLCTPlatformEvent() {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name IN ('Test Account 0','Test Account 1')];
        List<Id> accountIds = new List<Id>();
        Set<Id> accountSetIds = new Set<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }
        test.startTest();
        CDdLCTPlatformEventHelper.PlatformEventType eventType = CDdLCTPlatformEventHelper.PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD;
        List<Live_Chat_Transcript_Platform_Event__e > eList = CDdLCTPlatformEventHelper.createEvents(eventType, accountIds);
        system.assertEquals(accounts.size(), eList.size());
        CDdLCTPlatformEventHelper.publishEvents(eventType, accountSetIds);
        CDdLCTPlatformEventHelper.publishEvents(eventType, accountSetIds,'Test Live chat transcript event');
        test.getEventBus().deliver();        
        test.stopTest();
    }
    
    /**
    * @author Raghu Mandapaka
    * @description this method is to pass the INCREMENT_VENDORCHATCOUNT
    **/
    @isTest
    public static void testLCTPlatformEventTwo() {
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name IN ('Test Account 0','Test Account 1')]; 
        List<Id> accountIds = new List<Id>();
        Set<Id> accountSetIds = new Set<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }
        test.startTest();
        CDdLCTPlatformEventHelper.PlatformEventType eventType = CDdLCTPlatformEventHelper.PlatformEventType.INCREMENT_VENDORCHATCOUNT;
        List<Live_Chat_Transcript_Platform_Event__e > eList = CDdLCTPlatformEventHelper.createEvents(eventType, accountIds);
        system.assertEquals(accounts.size(), eList.size());
        CDdLCTPlatformEventHelper.publishEvents(eventType, accountSetIds);
        CDdLCTPlatformEventHelper.publishEvents(eventType, accountSetIds,'Test Live chat transcript event');
        test.getEventBus().deliver();
        test.stopTest();
    }  
}