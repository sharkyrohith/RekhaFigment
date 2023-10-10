/**
* @author Tia Xuan	
* @date 2019-04
*
* @description Test class for CDdLocalPromoCtrl, CDdLocalPromoSvc, CDdLocalPromoBatch
*/

@isTest
public class CDdLocalPromoTest {

    /**
	* @description testing local promo controller cond 1
	*/
    // @isTest static void test_local_promo_ctrl() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Parent Account')[0];
    //     insert testAcc;

    //     Account testAccChild = TDdAccountFactory.createAccounts('Local Promo Acc Child', 1,'Marketplace')[0];
    //     testAccChild.ParentId = testAcc.Id;
    //     insert testAccChild;
        

    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAcc.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
    //     Test.startTest();
    //     testAcc = [select Id, RecordType.DeveloperName from Account where Id=: testAcc.Id];
        
    //     Test.setCurrentPageReference(new PageReference('Page.PDdLocalPromo')); 
	// 	System.currentPageReference().getParameters().put('id', testAcc.Id);
    //     ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
    //     CDdLocalPromoCtrl ctrl = new CDdLocalPromoCtrl(controller);
    //     ctrl.createBountyProgram();
    //     PageReference pr = ctrl.close();
    //     Test.stopTest();
    // }

   	// /**
	// * @description testing local promo controller Cond 2
	// */
    // @isTest static void test_local_promo_ctrl2() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock.CDdLocalPromoCalloutConsumerMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Enterprise Marketplace')[0];
    //     testAcc.Restaurant_ID__c ='3';
    //     insert testAcc;

    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAcc.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
    //     Test.startTest();
    //     testAcc = [select Id, RecordType.DeveloperName,Restaurant_ID__c from Account where Id=: testAcc.Id];
        
    //     Test.setCurrentPageReference(new PageReference('Page.PDdLocalPromo')); 
	// 	System.currentPageReference().getParameters().put('id', testAcc.Id);
    //     ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
    //     CDdLocalPromoCtrl ctrl = new CDdLocalPromoCtrl(controller);
    //     ctrl.createBountyProgram();
    //     Test.stopTest();
    // }
    
    // /**
	// * @description testing local promo controller Cond 3
	// */
    // @isTest static void test_local_promo_ctrl3() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1, 'Corp Dev - Company')[0];
    //     testAcc.Restaurant_ID__c ='3';
    //     insert testAcc;
        
    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAcc.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
    //     Test.startTest();
    //     testAcc = [select Id, RecordType.DeveloperName from Account where Id=: testAcc.Id];
        
    //     Test.setCurrentPageReference(new PageReference('Page.PDdLocalPromo')); 
	// 	System.currentPageReference().getParameters().put('id', testAcc.Id);
    //     ApexPages.StandardController controller = new ApexPages.StandardController(testAcc);
    //     CDdLocalPromoCtrl ctrl = new CDdLocalPromoCtrl(controller);
    //     ctrl.createBountyProgram();
    //     Test.stopTest();
    // }
    
    // /**
	// * @description testing local promo service Cond 1
	// */
    // @isTest static void test_local_promo_svc() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Parent Account')[0];
    //     //testAcc.Restaurant_ID__c ='3';
    //     insert testAcc;

    //     Account testAccChild = TDdAccountFactory.createAccounts('Local Promo Acc Child', 1,'Marketplace')[0];
    //     testAccChild.Restaurant_ID__c ='3';
    //     testAccChild.ParentId = testAcc.Id;
    //     insert testAccChild;

    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAccChild.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;

    //     Opportunity opp2 = TDdOpportunityFactory.createPostSaleOpportunity('test', testAccChild.Id, 'Closed Won');
    //     //opp2.Menu_to_be_completed_by__c = null;
    //     //opp2.Menu_Setup_Method__c =  null;
    //     opp2.Tablet_Kit_Type__c = null;
    //     insert opp2;

    //     List<OpportunityLineItem> items = TDdOpportunityFactory.createOppProducts(opp2.Id);
    //     insert items;
    //     opp2.Type = 'weblinks';
    //     update opp2;

    //     Test.startTest();
    //     CDdLocalPromoSvc svc = new CDdLocalPromoSvc();
    //     svc.createLocalPromo(new List<Account>{testAccChild});
    //     Test.stopTest();
    // }
    
    // /**
	// * @description testing local promo service Cond 2
	// */
    // @isTest static void test_local_promo_svc2() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock.CDdLocalPromoCalloutNonValidMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Parent Account')[0];
    //     //testAcc.Restaurant_ID__c ='3';
    //     insert testAcc;

    //     Account testAccChild = TDdAccountFactory.createAccounts('Local Promo Acc Child', 1,'Marketplace')[0];
    //     testAccChild.Restaurant_ID__c ='3';
    //     testAccChild.ParentId = testAcc.Id;
    //     insert testAccChild;
        
    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAccChild.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
    //     Test.startTest();
    //     CDdLocalPromoSvc svc = new CDdLocalPromoSvc();
    //     svc.createLocalPromo(new List<Account>{testAccChild});
    //     Test.stopTest();
    // }
    
    
    // /**
	// * @description testing local promo batch
	// */
    // @isTest static void test_local_promo_batch() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Enterprise Marketplace')[0];
    //     testAcc.PAP__c = true;
    //     insert testAcc;
        
    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAcc.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
       
    //     Test.startTest();
    //     CDdLocalPromoBatch batch = new CDdLocalPromoBatch();
    //     Database.executeBatch(batch);
            
    //     batch = new CDdLocalPromoBatch(1);
        
    //     batch = new CDdLocalPromoBatch(1, '');
    //     Test.stopTest();
    // }

    // /**
	// * @description testing local promo scheduler
	// */
    // @isTest static void test_local_promo_sched() {
    //     Test.setMock(HttpCalloutMock.class, new CDdLocalPromoCalloutMock());

    //     Account testAcc = TDdAccountFactory.createAccounts('Local Promo Acc', 1,'Enterprise Marketplace')[0];
    //     testAcc.PAP__c = true;
    //     insert testAcc;
        
    //     Opportunity opp = TDdOpportunityFactory.createPostSaleOpportunity('test', testAcc.Id, 'Closed Won');
    //     //opp.Menu_to_be_completed_by__c = null;
    //     //opp.Menu_Setup_Method__c =  null;
    //     opp.Tablet_Kit_Type__c = null;
    //     insert opp;
        
       
    //     Test.startTest();
    //     CDdLocalPromoBatchSched sh1 = new CDdLocalPromoBatchSched();      
    //     String sch = '0 0 23 * * ?';
    //     system.schedule('Test check', sch, sh1);
    //     Test.stopTest();
    // }
 
}