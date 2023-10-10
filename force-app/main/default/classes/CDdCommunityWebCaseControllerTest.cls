/**
 * 
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Test class for CDdCommunityWebCaseController
 * 
 */
@isTest
public with sharing class CDdCommunityWebCaseControllerTest {
    public class CDdSalesforceValidMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            if (req.getEndpoint().contains('google')){
                res.setBody('{"success": true, "score": 0.6}');
            } else {
                res.setBody('ok');
            }
            return res;
        }
    }

    @isTest
    static void testCommunityWebCase() {
        Community_Webform_Picklist__c pl = new Community_Webform_Picklist__c();
        pl.Name = 'test';
        pl.Page__c ='contactsupport';
        pl.Language__c ='en_US';
        pl.Community__c ='dashers';
        pl.Page__c ='contactsupport';
        pl.Field_Name__c ='communities_dependent_dx_Category__c';
        pl.Field_Label__c ='Category';
        pl.Field_Value__c ='test';
        pl.Dependent_Field_Name__c ='communities_dx_Subcategory__c';
        pl.Dependent_Field_Label__c ='Subcategory';
        pl.Dependent_Field_Value__c ='test';
        insert pl;
 
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new CDdSalesforceValidMock());

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpCx = CDdCommunityWebCaseController.initCommunityWebCase('consumers', 'en_US', 'contactsupport');
        wrpCx.name = 'test';
        wrpCx.email = 'test@test.com';
        wrpCx.phone = '1234567890';
        wrpCx.category = 'tst';
        wrpCx.subcategory = 'test';
        wrpCx.description = 'test';
        String res = CDdCommunityWebCaseController.saveCommunityWebCase('consumers', 'en_US', JSON.serialize(wrpCx), 'contactsupport');
        System.assert(res == 'ok');

        res = CDdCommunityWebCaseController.saveCommunityWebCase('consumers', 'fr', JSON.serialize(wrpCx), 'contactsupport');
        System.assert(res == 'ok');

        res = CDdCommunityWebCaseController.saveCommunityWebCase('consumers', 'es', JSON.serialize(wrpCx), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpDx = CDdCommunityWebCaseController.initCommunityWebCase('dashers', 'en_US', 'contactsupport');
        wrpDx.name = 'test';
        wrpDx.email = 'test@test.com';
        wrpDx.phone = '1234567890';
        wrpDx.category = 'tst';
        wrpDx.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('dashers', 'en_US', JSON.serialize(wrpDx), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpMx = CDdCommunityWebCaseController.initCommunityWebCase('merchants', 'en_US', 'contactsupport');
        wrpMx.name = 'test';
        wrpMx.email = 'test@test.com';
        wrpMx.phone = '1234567890';
        wrpMx.category = 'tst';
        wrpMx.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('merchants', 'en_US', JSON.serialize(wrpMx), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpDiners = CDdCommunityWebCaseController.initCommunityWebCase('diners', 'en_US', 'contactsupport');
        wrpDiners.name = 'test';
        wrpDiners.email = 'test@test.com';
        wrpDiners.phone = '1234567890';
        wrpDiners.category = 'tst';
        wrpDiners.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('diners', 'en_US', JSON.serialize(wrpDiners), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpCouriers = CDdCommunityWebCaseController.initCommunityWebCase('couriers', 'en_US', 'contactsupport');
        wrpCouriers.name = 'test';
        wrpCouriers.email = 'test@test.com';
        wrpCouriers.phone = '1234567890';
        wrpCouriers.category = 'tst';
        wrpCouriers.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('couriers', 'en_US', JSON.serialize(wrpCouriers), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpRestaurants = CDdCommunityWebCaseController.initCommunityWebCase('restaurants', 'en_US', 'contactsupport');
        wrpRestaurants.name = 'test';
        wrpRestaurants.email = 'test@test.com';
        wrpRestaurants.phone = '1234567890';
        wrpRestaurants.category = 'tst';
        wrpRestaurants.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('restaurants', 'en_US', JSON.serialize(wrpRestaurants), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpCC = CDdCommunityWebCaseController.initCommunityWebCase('caviarforcompanies', 'en_US', 'contactsupport');
        wrpCC.name = 'test';
        wrpCC.email = 'test@test.com';
        wrpCC.phone = '1234567890';
        wrpCC.category = 'tst';
        wrpCC.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('work', 'en_US', JSON.serialize(wrpCC), 'contactsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpHS = CDdCommunityWebCaseController.initCommunityWebCase('consumers', 'en_US', 'healthandsafety');
        wrpHS.name = 'test';
        wrpHS.email = 'test@test.com';
        wrpHS.phone = '1234567890';
        wrpHS.category = 'tst';
        wrpHS.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('consumers', 'en_US', JSON.serialize(wrpHS), 'healthandsafety');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpHSDashers = CDdCommunityWebCaseController.initCommunityWebCase('dashers', 'en_US', 'healthandsafety');
        wrpHSDashers.name = 'test';
        wrpHSDashers.email = 'test@test.com';
        wrpHSDashers.phone = '1234567890';
        wrpHSDashers.category = 'tst';
        wrpHSDashers.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('dashers', 'en_US', JSON.serialize(wrpHSDashers), 'healthandsafety');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpHSMerchants = CDdCommunityWebCaseController.initCommunityWebCase('merchants', 'en_US', 'healthandsafety');
        wrpHSMerchants.name = 'test';
        wrpHSMerchants.email = 'test@test.com';
        wrpHSMerchants.phone = '1234567890';
        wrpHSMerchants.category = 'tst';
        wrpHSMerchants.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('merchants', 'en_US', JSON.serialize(wrpHSMerchants), 'healthandsafety');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpCFCSupport = CDdCommunityWebCaseController.initCommunityWebCase('restaurants', 'en_US', 'emailcfcsupport');
        wrpCFCSupport.name = 'test';
        wrpCFCSupport.email = 'test@test.com';
        wrpCFCSupport.phone = '1234567890';
        wrpCFCSupport.category = 'tst';
        wrpCFCSupport.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('restaurants', 'en_US', JSON.serialize(wrpCFCSupport), 'emailcfcsupport');
        System.assert(res == 'ok');

        CDdCommunityWebCaseController.CommunityWebCaseWrapper wrpLiveOpsSupport = CDdCommunityWebCaseController.initCommunityWebCase('restaurants', 'en_US', 'emailliveopssupport');
        wrpLiveOpsSupport.name = 'test';
        wrpLiveOpsSupport.email = 'test@test.com';
        wrpLiveOpsSupport.phone = '1234567890';
        wrpLiveOpsSupport.category = 'tst';
        wrpLiveOpsSupport.subcategory = 'test';
        res = CDdCommunityWebCaseController.saveCommunityWebCase('restaurants', 'en_US', JSON.serialize(wrpLiveOpsSupport), 'emailliveopssupport');
        System.assert(res == 'ok');

        Boolean resCaptcha = CDdCommunityWebCaseController.verifyRecaptcha('test', false);
        System.assert(resCaptcha == true);

        Test.stopTest();
    }

    @isTest
    static void testCommunityHelper() {

        Test.startTest();

        Map<String,List<CDdCommunityHelper.PicklistEntryWrapper>> plValues = CDdCommunityHelper.getDependentPicklist('Case', 'comm_dependent_cx_Category__c', 'communities_cx_Subcategory__c');
        System.assertEquals(plValues.isEmpty(), false);
       
        List<CDdCommunityHelper.PicklistEntryWrapper> pls = CDdCommunityHelper.getPicklistValues('Case', 'comm_dependent_cx_Category__c');
        System.assertEquals(pls.isEmpty(), false);

        Test.stopTest();
    }
}