/**
 * @description       : 
 * @author            : Tia Xuan
 * @group             : 
 * @last modified on  : 03-2022
 * @last modified by  : Tia Xuan
**/
@isTest
public class CDdGDPRCreateContactTest {

    /**
     * Begin - test class to execute if one of the classses is updated
     */
    private static List<System.Type> CLASS_REFERENCE = new  List<System.Type>{
        CDdGDPRCreateContactHelper.class,
        CDdGDPREmailHelper.class,
        CDdGDPRCassieAPI.class,
        CDdGDPRUnsubscribeLinkCtrl.class,
        CDdGDPREmailActionEventTriggerHandler.class,
        CDdGDPREmailActionEventTriggerHelper.class,
        CDdGDPREmailObj.class
    };
    public class CDdGDPRCreateContactMock implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().endsWith('authorize')) {
                res.setBody('{"token": "test","tokenExpiry": "'+ DateTime.Now().addHours(2)+'"}');
            } else if (req.getEndpoint().contains('GetDataSubjectCurrent')) {
                res.setBody('{"CurrentStandDak":{"URN1":"CX","Custom1":null,"Email1":"test@test.com","GUID":"6418f075-e6df-4a6a-8456-5456e166a3e0"},"CurrentPreferences":[{"BrandID":0,"BrandName":"Universal","PreferenceID":6487,"ChannelID":101,"ChannelName":"Surveys and Feedback","ChannelIsArchived":false,"ParentChannelID":97,"ParentChannelName":"Consumer Preferences (CX)","SubmissionID":null,"DateSubmitted":"2022-03-08T16:22:23.02","FormID":0,"FormName":null,"DivID":"CS Update","CheckboxID":"CS Update","FootnoteID":null,"FootnoteName":null,"FootnoteText":null,"HeaderID":0,"HeaderName":null,"HeaderText":null,"PrivacyID":1,"PrivacyPolicyName":"Default","StatementID":0,"StatementText":null,"ResponseChannel":"EM","SourceCode":"","PreferenceOptions":"","PreferenceValue":0,"PreferenceValidFrom":"","PreferenceValidTo":null}],"SyrenisID":693110}');
            } 
            return res;         
        }
    }  

    public class CDdGDPRCreateContactInCassieMock implements HttpCalloutMock{
        
        public HttpResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().endsWith('authorize')) {
                res.setStatusCode(200);
                res.setBody('{"token": "test","tokenExpiry": "'+ DateTime.Now().addHours(2)+'"}');
            } else if (req.getEndpoint().contains('GetDataSubjectCurrent')) {
                res.setStatusCode(204);
            } else if (req.getEndpoint().contains('Update')) {
                res.setStatusCode(200);
            } 
            return res;         
        }
    }  

    @testSetup 
    static void setup() { 
        GDPR_Setting__c setting = new GDPR_Setting__c();
        setting.Enable_GDPR_Contact_Creation__c = true;
        setting.Cassie_API_Key__c = 'test';
        setting.Cassie_Query_Endpoint__c = 'https://tapi-use-uat.cassiecloud.com/v3/oquery/GetDataSubjectCurrent?$expand=CurrentStandDak($select=Email1,URN1)&$expand=CurrentPreferences($select=ChannelID,ChannelName,PreferenceValue)';
        setting.Cassie_Update_Endpoint__c = 'https://tapi-use-uat.cassiecloud.com/';
        setting.Cassie_Named_Credential__c = 'Cassie';
        setting.Cassie_Authorization_URL__c = '/authorize';
        setting.Cassie_Query_Params__c = 'test';
        insert setting;  
    }

    @isTest
    static void testCreateContact(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdGDPRCreateContactMock());   
        Account consumer = TDdAccountFactory.createAccounts('test consumer', 1, 'Consumer or Dasher')[0];
        consumer.CustomerNo__pc = 123;
        consumer.PersonEmail = 'test@test.com';
        insert consumer;

        EventBusSubscriber[] subscribers = [SELECT Name, Type, Position, Retries, LastError 
                                            FROM EventBusSubscriber 
                                            WHERE Topic='GDPR_Email_Action__e'];
        System.assert(subscribers.size() > 0, 'Platform event should be fired');
        Test.stopTest();

    }

    @isTest
    static void testUpdateEmail(){
        Account consumer = TDdAccountFactory.createAccounts('test consumer', 1, 'Consumer or Dasher')[0];
        consumer.CustomerNo__pc = 123;
        consumer.PersonEmail = 'test@test.com';
        insert consumer;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdGDPRCreateContactMock());   
        consumer.PersonEmail = 'test1@test.com';
        update consumer;

        EventBusSubscriber[] subscribers = [SELECT Name, Type, Position, Retries, LastError 
                                            FROM EventBusSubscriber 
                                            WHERE Topic='GDPR_Email_Action__e'];
        System.assert(subscribers.size() > 0, 'Platform event should be fired');

        Test.stopTest();
    }

    @isTest
    static void testCreateContactWithPE(){
        Account consumer = TDdAccountFactory.createAccounts('test consumer', 1, 'Consumer or Dasher')[0];
        consumer.CustomerNo__pc = 123;
        consumer.PersonEmail = 'test@test.com';
        insert consumer;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdGDPRCreateContactMock());
        
        consumer = [select Id, CustomerNo__pc, PersonEmail, isPersonAccount, 
                            PersonHasOptedOutOfEmail, OptOutEmail__pc 
                    from Account 
                    where Id =: consumer.Id];
        GDPR_Email_Action__e ge=new GDPR_Email_Action__e();
        ge.Field_Name__c='PersonEmail';
        ge.Record_ID__c=consumer.id;
        ge.Persona__c=CDdGDPRConstants.CX_PERSONA_VALUE;
        ge.Old_Value__c='';
        ge.Service__c=CDdGDPRCreateContactHelper.CREATE_CONTACT_SERVICE;
        ge.JSON_Body__c= JSON.serialize(consumer); 

        CDdGDPRCreateContactHelper.processCreateContactEvents(new List<GDPR_Email_Action__e>{ge});
       
        Test.stopTest();

        Account acc = [select Id, PersonHasOptedOutOfEmail, OptOutEmail__pc from Account where Id =: consumer.Id];
        
        System.assert(acc.PersonHasOptedOutOfEmail == true, 'Opt out of email');
        System.assert(acc.OptOutEmail__pc == 'test@test.com', 'Opt out of email');
    }

    @isTest
    static void testCreateContactWithPECreateInCassie(){
        Account consumer = TDdAccountFactory.createAccounts('test consumer', 1, 'Consumer or Dasher')[0];
        consumer.CustomerNo__pc = 123;
        consumer.PersonEmail = 'test@test.com';
        insert consumer;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CDdGDPRCreateContactInCassieMock());
        
        consumer = [select Id, CustomerNo__pc, PersonEmail, isPersonAccount, 
                            PersonHasOptedOutOfEmail, OptOutEmail__pc 
                    from Account 
                    where Id =: consumer.Id];
        GDPR_Email_Action__e ge=new GDPR_Email_Action__e();
        ge.Field_Name__c='PersonEmail';
        ge.Record_ID__c=consumer.id;
        ge.Persona__c=CDdGDPRConstants.CX_PERSONA_VALUE;
        ge.Old_Value__c='';
        ge.Service__c=CDdGDPRCreateContactHelper.CREATE_CONTACT_SERVICE;
        ge.JSON_Body__c= JSON.serialize(consumer); 

        CDdGDPRCreateContactHelper.processCreateContactEvents(new List<GDPR_Email_Action__e>{ge});
       
        Test.stopTest();

        Account acc = [select Id, PersonHasOptedOutOfEmail, OptOutEmail__pc from Account where Id =: consumer.Id];
        
        System.assert(acc.PersonHasOptedOutOfEmail == false, 'Opt in of email');
        System.assert(String.isBlank(acc.OptOutEmail__pc) == true, 'Opt in of email');
    }

}