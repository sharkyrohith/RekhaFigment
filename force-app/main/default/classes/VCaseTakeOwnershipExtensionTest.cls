@IsTest 
public class VCaseTakeOwnershipExtensionTest 
{
	@IsTest(SeeAllData=false)
    public static void testTakeOwnership() 
    {
        init();
        
        Case c = new Case();
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        insert c;
		
        VCaseTakeOwnershipExtension ctrl = new VCaseTakeOwnershipExtension(new ApexPages.StandardController(c));
        ctrl.changeOwnershipToCurrentUser();
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