/**
 *
 * @author: Tia Xuan
 * @date: 2019-09
 * @description Test class for CDdDenaliHandler
 *
 */
@isTest
public with sharing class CDdDenaliTest {
    // public class CDdDenaliValidMock implements HttpCalloutMock {
    //     public HTTPResponse respond(HTTPRequest req) {

    //         HttpResponse res = new HttpResponse();
    //         res.setHeader('Content-Type', 'application/json');
    //         if (req.getEndpoint().contains('getbusinessobjectsummary')) {
    //             res.setBody('[{"busObId":123,"hasError":false,"errorMessage":"test"}]');
    //         } else {
    //             res.setBody('{"busObId":123, "busObRecId":123, "hasError":false,"errorMessage":"test", "relatedBusinessObjects":[{"busObRecId":123}], "groups":[{"hasError":false, "simpleResultsListItems":[{"busObId":123, "busObRecId":12346}]}]}');
    //         }
    //         res.setStatusCode(200);
    //         return res;
    //     }
    // }

    // @TestSetup
    // static void setup(){
    //      vCS__c s = VTestUtil.createVeltigSettings();
    //     insert s;

    //     Account acct = VTestUtil.createAccount('Test Account', true);
    //     acct.Deck_Rank__c = 'Queen';
    //     insert acct;

    //     Contact ctc = VTestUtil.createContact('Test', 'tst', acct);
    //     insert ctc;

    //     Case cs = new Case(
    //         AccountId = acct.Id,
    //         ContactId = ctc.Id,
    //         RecordTypeId = Schema.SObjectType.Case
    //                         .getRecordTypeInfosByName()
    //                         .get('Tablet Requests').getRecordTypeId(),
    //         subject = 'Test Case',
    //         Return_Label_Shipping_Contact_Name__c = 'test',
    //         Status = 'New',
    //         Tablet_Device_Type__c = 'Samsung Galaxy Tab E LTE',
    //         Shipping_Type__c = 'Standard',
    //         Request_Type__c  = 'Ship to Merchant (New Tablet, Printer)',
    //         Include_Large_Marketing_Kit__c = true,
    //         Include_Marketing_Kit__c = true,
    //         Return_Shipping_Address_State__c = 'Florida'
    //     );
    //     insert cs;
    // }

    // @isTest
    // static void testDenaliHandler() {
    //     Case cs =[select Id from Case limit 1];

    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new CDdDenaliValidMock());

    //     CDdDenaliHandler.saveCasesToDenali(new List<Id>{cs.Id});

    //     Case c =[select Id, Denali_Record_ID__c from Case where Id=: cs.Id];
    //     System.assert(c.Denali_Record_ID__c != null);

    //     Test.stopTest();
    // }

    // @isTest
    // static void testDenaliHandler2() {
    //     Case cs =[select Id, AccountId, ContactId from Case limit 1];
    //     cs.Denali_Record_ID__c ='test';
    //     cs.Denali_Specifics_Record_ID__c ='test';
    //     update cs;

    //     Account acc = new Account(Id=cs.AccountId, Denali_Record_ID__c ='test');
    //     update acc;

    //     Contact ctc = new Contact(Id=cs.ContactId, Denali_Record_ID__c ='test');
    //     update ctc;

    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new CDdDenaliValidMock());

    //     CDdDenaliHandler.saveCaseToDenali(cs.Id, true);

    //     Case c =[select Id, Denali_Record_ID__c from Case where Id=: cs.Id];
    //     System.assert(c.Denali_Record_ID__c != null);

    //     Test.stopTest();
    // }

    // @isTest
    // static void testDenaliHandlerOther() {
    //     Case cs =[select Id from Case limit 1];

    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new CDdDenaliValidMock());

    //     CDdDenaliHandler.getBusinessObjectId('test', null);
    //     CDdDenaliHandler.getBusinessObjectFields('test', null);
    //     CDdDenaliHandler.getBusinessObjectTemplate('test', new List<String>{'test'}, null);
    //     CDdDenaliHandler.getBusinessRelatedObject('test', 'test', 'test', null);
    //     CDdDenaliHandler.searchBusinessObject('test', 'test', null);

    //     Test.stopTest();
    // }

    // @isTest
    // static void testDenaliBatch() {
    //     Id userId = UserInfo.getUserId();
	// 	Validation_Bypass__c validation = new Validation_Bypass__c(SetupOwnerId = userId);
    //     validation.Bypass_Case_Validations__c = true;
    //     validation.Bypass_Opportunity_Validations__c = true;
    //     insert validation;

    //     Case cs =[select Id, AccountId, ContactId from Case limit 1];
    //     cs.Denali_Record_ID__c ='test';
    //     cs.Denali_Specifics_Record_ID__c ='test';
    //     cs.Status = 'Approved';
    //     update cs;

    //     Account acc = new Account(Id=cs.AccountId, Denali_Record_ID__c ='test');
    //     update acc;

    //     Contact ctc = new Contact(Id=cs.ContactId, Denali_Record_ID__c ='test');
    //     update ctc;

    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new CDdDenaliValidMock());

    //     // CDdDenaliSched.setSchedule();
    //     Test.stopTest();
    // }

    // @isTest
    // static void testDenaliController() {
    //     Case cs =[select Id from Case limit 1];

    //     Test.startTest();

    //     Test.setMock(HttpCalloutMock.class, new CDdDenaliValidMock());

    //     PageReference pageRef = Page.PDdSendCaseToDenali;
    //     pageRef.getParameters().put('id', cs.Id);
    //     Test.setCurrentPage(pageRef);

    //     ApexPages.StandardController sc = new ApexPages.StandardController(cs);
    //     CDdSendCaseToDenaliController ctrl = new CDdSendCaseToDenaliController(sc);
    //     ctrl.sendToDenali();
    //     ctrl.back();

    //     Case c =[select Id, Denali_Record_ID__c from Case where Id=: cs.Id];
    //     // New Denali V2 API does not automatically update Denali_Record_Id__c
    //     System.assert(c.Denali_Record_ID__c == null);

    //     Test.stopTest();
    // }

    // @isTest
    // static void testDenaliObjects() {

    //     Test.startTest();

    //     CDdDenaliObjects.BusinessObject bo = new CDdDenaliObjects.BusinessObject();
    //     bo.fieldDefinitions = new List<CDdDenaliObjects.BusinessObjectField>();
    //     bo.relationships = new List<CDdDenaliObjects.BusinessObjectRelationship>();

    //     CDdDenaliObjects.BusinessObjectField bof = new CDdDenaliObjects.BusinessObjectField();
    //     bof.fieldId = 'test';
    //     bof.name = 'test';
    //     bof.value = 'test';
    //     bof.dirty = true;

    //     CDdDenaliObjects.BusinessObjectRelationship bor = new CDdDenaliObjects.BusinessObjectRelationship();
    //     bor.cardinality = 'test';
    //     bor.description = 'test';
    //     bor.displayName = 'test';
    //     bor.relationshipId = 'test';
    //     bor.target = 'test';
    //     bor.errorCode = 'test';
    //     bor.errorMessage = 'test';
    //     bor.hasError = true;

    //     CDdDenaliObjects.BusinessObjectTemplate bot = new CDdDenaliObjects.BusinessObjectTemplate();
    //     bot.busObId = 'test';
    //     bot.busObRecId = 'test';
    //     bot.cacheScope = 'test';
    //     bot.persist = true;
    //     bot.fields = new List<CDdDenaliObjects.BusinessObjectField>();

    //     CDdDenaliObjects.BusinessObjectTemplateRequest botr = new CDdDenaliObjects.BusinessObjectTemplateRequest();
    //     botr.busObId = 'test';
    //     botr.fieldNames = new List<String>();
    //     botr.includeRequired = true;
    //     botr.includeAll = true;

    //     CDdDenaliObjects.BusinessObjectRelationshipTemplate bort = new CDdDenaliObjects.BusinessObjectRelationshipTemplate();
    //     bort.busObId = 'test';
    //     bort.parentBusObId = 'test';
    //     bort.parentBusObPublicId = 'test';
    //     bort.parentBusObRecId = 'test';
    //     bort.relationshipId = 'test';
    //     bort.busObRecId = 'test';
    //     bort.cacheScope = 'test';
    //     bort.persist = true;
    //     bort.fields = new  List<CDdDenaliObjects.BusinessObjectField>();

    //     CDdDenaliObjects.BusinessObjectSaveResult bosr = new CDdDenaliObjects.BusinessObjectSaveResult();
    //     bosr.busObPublicId = 'test';
    //     bosr.busObRecId = 'test';
    //     bosr.errorCode = 'test';
    //     bosr.errorMessage = 'test';
    //     bosr.hasError = true;

    //     CDdDenaliObjects.BusinessObjectRelationshipResult borr = new CDdDenaliObjects.BusinessObjectRelationshipResult();
    //     borr.parentBusObId = 'test';
    //     borr.parentBusObPublicId = 'test';
    //     borr.parentBusObRecId = 'test';
    //     borr.relationshipId = 'test';
    //     borr.relatedBusinessObjects = new List<CDdDenaliObjects.BusinessObjectRelationshipResultRelated>();
    //     borr.errorCode = 'test';
    //     borr.errorMessage = 'test';
    //     borr.hasError = true;

    //     CDdDenaliObjects.BusinessObjectRelationshipResultRelated borrr = new CDdDenaliObjects.BusinessObjectRelationshipResultRelated();
    //     borrr.busObId = 'test';
    //     borrr.busObPublicId = 'test';
    //     borrr.busObRecId = 'test';

    //     CDdDenaliObjects.BusinessObjectSearch bos = new CDdDenaliObjects.BusinessObjectSearch();
    //     bos.busObIds = new List<String>();
    //     bos.searchText = 'test';

    //     CDdDenaliObjects.BusinessObjectSearchResult bosRes = new CDdDenaliObjects.BusinessObjectSearchResult();
    //     bosRes.groups = new List<CDdDenaliObjects.BusinessObjectSearchResultGroup>();
    //     bosRes.title = 'test';
    //     bosRes.errorCode = 'test';
    //     bosRes.errorMessage = 'test';
    //     bosRes.hasError = true;

    //     CDdDenaliObjects.BusinessObjectSearchResultGroup bosResGrp = new CDdDenaliObjects.BusinessObjectSearchResultGroup();
    //     bosResGrp.isBusObTarget = true;
    //     bosResGrp.simpleResultsListItems = new List<CDdDenaliObjects.BusinessObjectSearchResultGroupListItem>();
    //     bosResGrp.errorCode = 'test';
    //     bosResGrp.errorMessage = 'test';
    //     bosResGrp.hasError = true;

    //     CDdDenaliObjects.BusinessObjectSearchResultGroupListItem bosResGrpListItem = new CDdDenaliObjects.BusinessObjectSearchResultGroupListItem();
    //     bosResGrpListItem.busObId = 'test';
    //     bosResGrpListItem.busObRecId = 'test';

    //     Test.stopTest();
    // }
}