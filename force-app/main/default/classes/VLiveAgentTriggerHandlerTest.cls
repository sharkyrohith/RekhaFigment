@isTest
private class VLiveAgentTriggerHandlerTest{
    @testSetup static void testSetup() {
        CDdContactTriggerHelper.insertCampaign();
    }

    @isTest
    static void link_transcript_to_case() {
        Trigger_Control_Panel__c tcp=new Trigger_Control_Panel__c();
        tcp.Name='Control Panel';
        tcp.Account_Trigger_Enabled__c=True;
        insert tcp;
     
        Account acc = new Account(Name='DoorDash HQ (123 Street)'); //,Market_Area__c='ATL - Atlanta');
        insert acc;
        
        Contact con = new Contact(
            FirstName='john',
            LastName='doe',
            Email='john@doe.com',
            AccountId=acc.Id);
        insert con;

        Opportunity opp = TDdOpportunityFactory.createOpportunity('test', acc.Id, con.Id, 'New');
        opp.Bulk_Activation__c = true;
        insert opp;

        List<OpportunityLineItem> items = TDdOpportunityFactory.createOppProducts(opp.Id);
        insert items;
        
        Asset ast = new Asset(  AccountId=acc.Id,ContactId=con.Id, 
                                Opportunity__c = opp.Id, Name='testing', 
                                Post_Sale_Activations_Case_Created__c = true);
        insert ast;
        
        Entitlement ent = new Entitlement(Name='Testing',AccountId=acc.Id, StartDate=Date.valueof(System.now().addDays(-2)), 
            EndDate=Date.valueof(System.now().addYears(2)), AssetId=ast.Id);
        insert ent;
        
        EntitlementContact ec2 = new EntitlementContact(EntitlementId=ent.Id,ContactId=con.Id);
        insert ec2;
        
        Case c1 = new Case( ContactId=con.Id,  AccountId=con.AccountId, Subject='Test Subject',
            chatkey__c = '123', EntitlementId=ent.Id, ChatWaitTime__c=15, ChatDuration__c=43,
            Origin='Webform_B2B');
        insert c1;
        
        Case c2 = new Case(ContactId=con.Id, AccountId=con.AccountId,Subject='Test Subject',chatkey__c = '123',
            EntitlementId=ent.Id, Origin='Webform_B2B');
        insert c2;

        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='Standard SLA' 
            and IsActive = true LIMIT 1];
        if (lstEntitlementProcess.size()>0){
            ent.SlaProcessId = lstEntitlementProcess[0].id;
            update ent;        
        }
     
        LiveChatVisitor visitor = new LiveChatVisitor();

        insert visitor;
       
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit 
        LiveChatTranscript tx = new LiveChatTranscript(
            chatKey = '123', liveChatVisitorId = visitor.id, Status='Completed',
            StartTime= datetime.newInstance(2017, 9, 15, 12, 30, 0), EndTime=datetime.newInstance(2017, 9, 15, 13, 30, 0),
            RequestTime=datetime.newInstance(2014, 9, 15, 13, 30, 0), DasherNo__c=2345, CustomerNo__c=35463,
            DeliveryNo__c=64754, DeliveryUUID__c='64754' );
            
        insert tx;
        TriggerFactory.isTriggerExecuted = false;
        tx.caseId=c1.Id;
        update tx;

        tx = [ SELECT id, caseId, chatKey FROM LiveChatTranscript WHERE id = :tx.id ];
    
        System.assertEquals( c1.chatkey__c, tx.chatKey );
        System.assertEquals( c1.id, tx.caseId );

        TriggerFactory.isTriggerExecuted = false;
        delete tx;
        TriggerFactory.isTriggerExecuted = false;
        undelete tx;       
    }

}