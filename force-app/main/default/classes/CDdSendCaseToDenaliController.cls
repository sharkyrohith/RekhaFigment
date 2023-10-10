/**
 * @description       : Use Mx Order for tablet order fulfillment
 * @author            : 
 * @last modified on  : 04-29-2022
**/
public without sharing class CDdSendCaseToDenaliController {
    String caseId {get; set;}
    
    public CDdSendCaseToDenaliController(ApexPages.StandardController standardController){
        caseId = standardController.getId();
    }
 
    public PageReference sendToDenali(){
        CDdMxOrderProcessController.processMxOrder(caseId);
        PageReference pr = new PageReference('/' + caseId);
        pr.setRedirect(true);
        return pr;
    }

    public PageReference back(){
        
        PageReference pr = new PageReference('/' + caseId);
        pr.setRedirect(true);
        return pr;
    }
}