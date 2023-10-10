@isTest
public class CDdBatchConvertLeadsToOppTest {

    public static void setGDPROff(){
        //GDPR
        CDdGDPREmailHelper.ENABLE_CREATE_CONTACT = false;
        CDdGDPREmailHelper.ENABLE_SUBSCRIPTION = false;
        CDdGDPREmailHelper.ENABLE_DELIGHTED_TASK = false;
    }
    
    @isTest(SeeAllData=true)
    static void convertLeadtoOpp() {

        //GDPR
        setGDPROff();
        
        Id leadId;
        Id acctId;
        List<UserRole> roleIds = [select Id from UserRole where DeveloperName = 'COO']; 
        List<User> selfServiceUsers = TDdAccountFactory.createUsers(2, null, roleIds[0].id);
        selfServiceUsers[0].LastName = 'formstackTestUser';
        insert selfServiceUsers;
        List<PermissionSetAssignment> psas = new List<PermissionSetAssignment>(); 
        PermissionSetAssignment psa; 
        for(User selfServiceUser : selfServiceUsers){
            psa = new PermissionSetAssignment(); 
            psa.PermissionSetId = '0PS1a0000001bYE' ;
            psa.AssigneeId = selfServiceUser.id; 
            psas.add(psa);
        }
        insert psas;
        String TEST_STORE_ID = '12345678'; 
        List<Self_Serve_Users__c> selfServeUsersSettings = Self_Serve_Users__c.getAll().values(); 
        Self_Serve_Users__c ssUser; 
        
        System.runAs(selfServiceUsers[0]) {
            
            CDdContactTriggerHelper.insertCampaign();
            CDdAccountHelperMethods.testingAccountFormStack = false;  
            
            List<Account> accList = CDdTestDataFactory.createSObjectList('Account',1,false);            
            
            Campaign campaignToInsert = new Campaign();
            campaignToInsert.Name = System.label.CampaignNameMxAcqMktg_BOFU;
            campaignToInsert.Title__c = 'Unmanaged Caviar to DD X-Sell';
            insert campaignToInsert;  
            
            Account acc = accList[0];
            acc.Name = 'Test Acc';
            acc.phone = '0256157848';
            acc.BillingCountryCode = 'US';
            acc.Market_Area__c = 'Northern California - East Bay';
            acc.Business_ID__c = 123456;
            acc.Formstack_Version__c = 'New Store';
                                
            insert acc;
            
            Contact con = new Contact();
    
            con.firstName = 'moCaseMilestone1';
            con.LastName = 'Con1'; 
            con.Email = 'moCaseMilestone1Con1@dd.com';
            con.accountId=acc.Id;
            con.Birthdate = Date.newInstance(1991, 9, 29);
            
            insert con;
            
            Lead newLead = TDdLeadFactory.createLeads('Con1', 1, false)[0];
            newLead.FirstName = 'moCaseMilestone1'; 
            newLead.Company = acc.Name;
            newLead.Account__c = acc.Id; 
            newLead.Email = con.Email;
            newLead.Primary_Campaign_Source__c = campaignToInsert.Id;
            insert newLead;
            
            Opportunity opp = TDdOpportunityFactory.createOpportunityByDevRT('Test Opp', acc.Id, con.Id, 'Untouched', 'DoorDash_Drive');
            opp.Tablet_Delivery_Method__c = '';
            opp.Tablet_Kit_Type__c = '';
            opp.Notes__c = 'Test Notes';
            opp.Order_Protocol__c = '';
            opp.Pricing_Structure__c = 'Other';
            opp.Planned_Integration_Path__c = 'Drive Form';
            opp.Payment_Protocol__c = 'Credit Card';
            opp.Accepts_Tips__c = 'Yes';
            opp.Decision_Maker__c = con.Id;
            opp.Catering_setup_exists__c = 'Yes';
            opp.Current_Delivery_Channels__c = 'None';
            opp.Type = 'Weblinks';
            opp.Contact_Manager_Owner_Name__c = 'Test User';
            opp.Contact_Manager_Owner_Email__c = 'test@test.com';
            opp.Decision_Maker__c = con.Id;
            opp.Accounting_Contact__c = con.Id;
            opp.Weblink_Activation_Date__c = System.today();
            
            insert opp;
                
            Test.startTest(); 
                
                CDdBatchConvertLeadsToOpp obj1 = new CDdBatchConvertLeadsToOpp('SELECT Id FROM Opportunity where Id=\''+opp.Id+'\'');
                Database.executeBatch(obj1);   
            Test.stopTest();
            
            system.assert([SELECT Id, isConverted FROM Lead where Id=:newLead.Id].IsConverted == True);
        }
        
    }
}