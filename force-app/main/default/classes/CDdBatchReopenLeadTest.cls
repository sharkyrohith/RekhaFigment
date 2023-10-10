@isTest
private class CDdBatchReopenLeadTest {
    
    @isTest static void testBatchJob() {
        Opportunity_Inversion_Settings__c settings = TDdOpportunityFactory.setCustomSettings(); 
        
        List<Lead> leads = TDdLeadFactory.createLeads('TestLead',4,false);
        List<Id> leadIds = new List<Id>(); 
        List<Lead> refreshedLeads; 
        Id untouchedLead; 
        Integer count = 0; 

        for(Lead currLead : leads) {
            if(count <3){
                currLead.Status = 'Not Interested - Cool Down'; 
                count++;
            }
        }
        insert leads;
        for(Lead currLead : leads) {
            if(currLead.Status == 'Not Interested - Cool Down'){
                currLead.Lead_Reopen_Date__c = System.Today(); 
            } else {
                untouchedLead = currLead.id;
            }
            leadIds.add(currLead.Id);
        }
        update leads;                
        Test.startTest(); 
        Database.executeBatch(new CDdBatchReopenLead());
        Test.stopTest(); 
        refreshedLeads = [Select Id, Status, FirstName, ownerid, Lead_Reopen_Date__c, Reopened_Lead__c 
                            From Lead 
                            where id in : leadIds]; 
        for(Lead currLead : refreshedLeads) {
            if(currLead.Id == untouchedLead) {
                System.assertNotEquals(settings.Reopened_Lead_Owner__c,currLead.Ownerid,'Invalid Owner');
                System.assertEquals(FALSE, currLead.Reopened_Lead__c); 

            } else {
                System.assertEquals(settings.Reopened_Lead_Owner__c,currLead.Ownerid,'Invalid Owner');
                System.assertEquals(TRUE, currLead.Reopened_Lead__c); 
                System.assertEquals(System.Today(), currLead.Lead_Reopen_Date__c);
            }
        }
    }
    @isTest static void testScheduleBatch() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('Sample_Heading', CRON_EXP, new CDdScheduleReopenLead() );   
        Test.stopTest();
    }   

}