@isTest
public class vTestCaseDelete {
	
    static testMethod void validateCaseDelete(){
        init();
    	Case c = new Case(Priority = 'Normal', Subject='test debug',Origin='email',SuppliedEmail='sfadmin+test@veltig.com',SuppliedName='Veltig Consulting');
		insert c;
        LIST<Case> cList = new LIST<Case>();
        cList.add(c);
        test.startTest();
        vCaseDelete.vDeleteCase(cList);
        test.stopTest();
    }
    
    private static void init()
    {
        Trigger_Control_Panel__c cs = new Trigger_Control_Panel__c();
        cs.Name = 'Control Panel';
        insert cs;
        
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