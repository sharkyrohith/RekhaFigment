/**
 * @description       : 
 * @author            : Dinesh Annapareddy
 * @group             : 
 * @last modified on  : 11-25-2021
 * @last modified by  : Tia Xuan
**/
@isTest
public class CDdGDPRSubscriptionsTest {
    /**
     * Begin - test class to execute if one of the classses is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new  List<System.Type>{
        CDdGDPRCreateContactHelper.class,
        CDdGDPREmailHelper.class,
        CDdGDPRSubscriptionsHelper.class,
        CDdGDPREmailActionEventTriggerHelper.class,
        CDdGDPREmailObj.class
    };
    private static final Decimal TEST_BUSINESS_ID = 76789.0;
    @testSetup 
    static void setup() {          
        // insert parent account
        String parentAccountName = 'Test Parent Account';
        Decimal businessId = TEST_BUSINESS_ID;        
        Account parentAccount = TDdAccountFactory.createAccounts(parentAccountName, 1, 'Parent Account')[0];
        parentAccount.BillingCountry = 'United States';
        parentAccount.Business_Id__c = businessId;
        parentAccount.Deck_Rank__c = 'Jack';
        insert parentAccount;
        Contact parentContact = TDdAccountFactory.createContacts(1, parentAccount.Id)[0];
        parentContact.Email = 'parent.contact@testdd.com';
        parentContact.Secondary_Email__c = 'parent.contact2@testdd.com';
        parentContact.Quartenary_Email__c = 'parent.contact3@testdd.com';
        parentContact.Tertiary_Email__c = 'parent.contact4@testdd.com';

        insert parentContact;

        GDPR_Setting__c setting = new GDPR_Setting__c();
        setting.Enable_GDPR_Contact_Subscription__c = true;
        setting.Encryption_Key__c = 'J50e5Dt4XttpEm+ngWe4juFK4RvZ3judll1LxGOacvg=';
        setting.CX_Unsubscribe_Link__c = '{0}';
        setting.DX_Unsubscribe_Link__c = '{0}';
        setting.MX_Unsubscribe_Link__c = '{0}';
        setting.Enable_Delighted_Task_Trigger__c = true;
        insert setting;
    }

    @isTest
    static void testCassieUnsubscribe(){
        Test.startTest();
            CDdGDPREmailObj.CDdGDPRSubscriptions payload =  getPayload();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            req.requestURI = '/services/apexrest/CassieSubscriptions';  
            req.httpMethod = 'POST';
            req.addHeader('Content-Type', 'application/json');
            req.requestBody=Blob.valueof(JSON.serialize(payload));
            RestContext.request = req;
            RestContext.response = res;
            CDdGDPRSubscriptionsAPI.doPost();
        Test.stopTest();
        List<contact> contacts= new List<Contact>([ select  id,Email,Secondary_Email__c,
                                                            Quartenary_Email__c,OptOutEmail__c,
                                                            HasOptedOutOfEmail,isPersonAccount,
                                                            CustomerNo__c,DasherNo__c 
                                                    from contact 
                                                    where HasOptedOutOfEmail =: true] );
        boolean validate=false;
        if (contacts.size()>0) {
            validate=True;
        }
        System.assertEquals(True, validate,'RecordsUpdated');  
    }

    static CDdGDPREmailObj.CDdGDPRSubscriptions getPayload(){
        CDdGDPREmailObj.CDdGDPRSubscriptions payload = new CDdGDPREmailObj.CDdGDPRSubscriptions();
        List<CDdGDPREmailObj.CDdGDPRSubscription> subList = new List<CDdGDPREmailObj.CDdGDPRSubscription>();
        subList.add(getUnSubscription());
        Contact con = [   select  id,Email,Secondary_Email__c,
                                Quartenary_Email__c,isPersonAccount,
                                CustomerNo__c,DasherNo__c
                            from Contact];

        if(con.Email != null){
            payload.Subscriptions=subList;
            payload.Email = con.Email;
            payload.CassieID ='CassieID';
            if (con.isPersonAccount == FALSE) {
                payload.Persona = 'MX';
            } else if (con.CustomerNo__c != null) {
                payload.Persona = 'CX';
            } else {
                payload.Persona = 'DX';
            } 
        }

        return payload;
    }

    static CDdGDPREmailObj.CDdGDPRSubscription getUnSubscription(){
        CDdGDPREmailObj.CDdGDPRSubscription unsubs=  new CDdGDPREmailObj.CDdGDPRSubscription();
        unsubs.channelID = 1;
        unsubs.channelName = 'Channel 1';
        unsubs.OptOut = true;

        return unsubs;
    } 

    @isTest
    static void testCassieUnsubscribeLink(){

        Account consumer = TDdAccountFactory.createAccounts('test consumer', 1, 'Consumer or Dasher')[0];
        consumer.CustomerNo__pc = 123;
        consumer.PersonEmail = 'test@test.com';
        insert consumer;

        List<Case> cases = TDdCaseFactory.createCaseRecords(1, 'Support');
        cases[0].Language__c = 'English';
        cases[0].AccountId = consumer.Id;
        insert cases;

       
        Test.startTest();
        CDdGDPRUnsubscribeLinkCtrl ctrl = new CDdGDPRUnsubscribeLinkCtrl();
        ctrl.strEmail = 'test@test.com';
        ctrl.strPersona = 'CX';
    
        System.assert(ctrl.subLink != null ,'Unsubscribe link not found');  

        CDdGDPRUnsubscribeLinkCtrl ctrl2 = new CDdGDPRUnsubscribeLinkCtrl();
        ctrl2.strEmail = 'test@test.com';
        ctrl2.strCaseId = cases[0].Id;
        ctrl2.strEmailType = 'text';

        System.assert(ctrl2.textTypes.size() == 1 ,'Should be 1');  
        System.assert(ctrl2.htmlTypes.size() == 0 ,'should be 0');  
        System.assert(ctrl2.subLink != null ,'Unsubscribe link not found');  
            
        Test.stopTest();   
    }
}