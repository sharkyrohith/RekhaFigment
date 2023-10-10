@IsTest 
private class VCaseSendEmailExtensionTest 
{
    @IsTest(SeeAllData=false) 
    public static void testEmail() 
    {
        init();
        
        Case c = new Case();
        c.Subject = 'test 01';
        c.Description = 'this is a test';
        c.SuppliedName = 'tester 01';
        c.SuppliedEmail = 'tester01@test.com';
        c.Origin = 'Email';
        insert c;
		
        test.startTest();
        
        VCaseSendEmailExtension ctrl = new VCaseSendEmailExtension(new ApexPages.StandardController(c));
        ctrl.saveCase();
        
        test.stopTest();
    }
    
    private static void init()
    {
        List<User> userList = [Select Id From User Where IsActive=true And Profile.Name = 'System Administrator' And Id != :UserInfo.getUserId() Limit 1];
        
        if(!userList.isEmpty())
        {
            System.runAs(userList[0])
            {
               EmailTemplate et = new EmailTemplate();
                et.Name = 'Test Template 1231231';
                et.DeveloperName = 'Test_Template_1231231';
                et.Subject = 'Test';
                et.Body = 'Test';
                et.TemplateType = 'text';
                et.FolderId = UserInfo.getUserId();
                insert et; 
                
                Email_Publisher_Template__c cs = new Email_Publisher_Template__c();
                cs.Name = 'Default';
                cs.Email_Template_Id__c = et.Id;
                insert cs;
            }
        }
        
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