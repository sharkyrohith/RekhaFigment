/**
* @author: ed-kim
* @date: 2019-03
* @description In Store Promos Ctrl
*/ 
public class CDdLocalPromoCtrl {
    // final ApexPages.StandardController controller;
    // public Account acct { get; set; }
    // public List<Opportunity> promoOpps { get; set; }
    // public CDdLocalPromoSvc localPromoSvc;
    // // public static final vCS__c SETTINGS = vCS__c.getInstance();
    
    // public CDdLocalPromoCtrl(ApexPages.StandardController controller) {
    //     this.controller = controller;
    //     this.acct = (Account) controller.getRecord();
    //     this.localPromoSvc = new CDdLocalPromoSvc();

    //     List<Opportunity> localPromoOpps = [SELECT CloseDate, Id, LastModifiedDate, Name, OwnerId, Owner.Name, Type
    //                                         FROM Opportunity
    //                                         WHERE AccountId	= :this.acct.Id 
    //                                         AND RecordType.DeveloperName='Post_Sale'
    //                                         AND StageName = 'Closed Won'
    //                                         AND Type in ('Weblinks', 'In-Store Marketing')];
    //     this.promoOpps = localPromoOpps;
    // }
    
    // public void createBountyProgram() {
    //     if (acct.RecordType.DeveloperName == 'Parent_Account') {
    //         List<Account> childAccts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Prospect' AND ParentId = :acct.Id];
    //         for (Account childAcct : childAccts) {
    //             childAcct.PAP__c = true;
    //         }
    //         Database.update(childAccts, false);

    //         CDdLocalPromoBatch promoBatch = new CDdLocalPromoBatch(0,'AND ParentId =\'' + acct.Id + '\' ');
    //         Database.executebatch(promoBatch, 20);
        
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Batch creating ' + childAccts.size() + ' promotions, please check the child accounts later'));
    //     } else if (acct.RecordType.DeveloperName == 'Prospect' || acct.RecordType.DeveloperName == 'Enterprise_Marketplace' ) {
    //         if (localPromoSvc.createLocalPromo(new List<Account> {acct})) {
    //             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Bounty Program Created'));
    //         } else {
    //             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There was an error with your request'));
    //         }
    //     } else {
    //         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Failed to create promotion. Please contact your administrator.'));
    //     }
    // }

    // public PageReference close() {
    //     return new PageReference('javascript:window.close()');
    // }
}