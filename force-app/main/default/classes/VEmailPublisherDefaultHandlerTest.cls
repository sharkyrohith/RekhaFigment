@IsTest
public class VEmailPublisherDefaultHandlerTest 
{
	@IsTest(SeeAllData=false) 
    public static void test() 
    {
    	init();
        
        List<RecordType> supportRecordType = [Select Id, Name From RecordType Where SobjectType='Case' And DeveloperName='Customer' Limit 1];
        Case c = new Case();
        c.RecordTypeId = supportRecordType[0].Id;
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        insert c;
        
        //Create test data here
        Exception failureDuringExecution = null;
    
        List<Map<String, Object>> defaultSettingAsUntypedObject = new List<Map<String, Object>>
        {
          new Map<String, Object>
          {
                'targetSObject' => new EmailMessage(),
                'contextId' => c.Id,
                'actionType' => 'Email',
                'actionName' => 'Case.Email',
                'fromAddressList' => new List<String> { 'salesforce@test.com' }
          }
        };
        
        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsUntypedObject), List<QuickAction.SendEmailQuickActionDefaults>.class);
    
        Test.startTest();
        try { (new VEmailPublisherDefaultHandler()).onInitDefaults(defaultsSettings); }
        catch(Exception failure) { failureDuringExecution = failure; }
    
        Test.stopTest();
    
        System.assertEquals(null, failureDuringExecution, 'There was an exception thrown during the test!');        
    }
    
    private static void init()
    {        
        Trigger_Control_Panel__c cs = new Trigger_Control_Panel__c();
        cs.Name = 'Control Panel';
        insert cs;
        
        vCS__c cs1 = new vCS__c();
        cs1.CasePopulateContact__c = true;
        cs1.CasePopulatePersonAccount__c = true;
        insert cs1;
        
        Account acc = new Account();
        acc.RecordTypeId = '0121a0000006PxA';
        acc.Name = 'DoorDash HQ';
        insert acc;
        
        List<BusinessHours> bhList = [Select Id, Name From businesshours Limit 1];
        if(!bhList.isEmpty())
        {
            Entitlement et = new Entitlement();
        	et.Name = 'Standard SLA';
        	et.StartDate = date.Today();
            et.AccountId = acc.Id;
            et.Type = 'Phone Support';
			et.BusinessHoursId = bhList[0].Id;
        	insert et;
        }
    }
}