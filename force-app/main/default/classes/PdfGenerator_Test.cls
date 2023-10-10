@isTest
private class PdfGenerator_Test {

  static Opportunity opportunity;
  static Account account;

  static {
    Trigger_Control_Panel__c cp = new Trigger_Control_Panel__c();
        cp.Name = 'MAin';
        cp.Opportunity_Trigger_Enabled__c = true;
        cp.Account_Trigger_Enabled__c = true;
        upsert cp;
    
    account = VTestUtil.createAccount('Test acc', true);
    insert account;

    opportunity = new Opportunity();
    opportunity.Name = 'Test Opportunity';
    opportunity.stagename='Prospecting';
    opportunity.CloseDate = system.date.today();
    opportunity.AccountId = account.Id;
    opportunity.Menu_to_be_completed_by__c = null;
    opportunity.Menu_Setup_Method__c =  null;
    opportunity.Tablet_Kit_Type__c = null;
    insert opportunity;
  }

  static testMethod void testPdfGenerator() {

    PageReference pref = Page.PdfGenerator;
    pref.getParameters().put('id',opportunity.id);
    Test.setCurrentPage(pref);

    PdfGeneratorController con = new PdfGeneratorController(new ApexPages.StandardController(Opportunity));


    Test.startTest();

    // populate the field with values
    con.parentId = opportunity.id;
    con.Name = 'My Test PDF';

    // submit the record
    pref = con.savePdf();

    // assert that they were sent to the correct page
    System.assertEquals(pref.getUrl(),'/'+opportunity.id);

    // assert that an attachment exists for the record
    System.assertEquals(1,[select count() from attachment where parentId = :opportunity.id]);

    Test.stopTest(); 

  }
}