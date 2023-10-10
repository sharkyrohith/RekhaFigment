/**
 * @author Mahesh Chouhan
 * @date  June 2023
 * @description Test Class for CDdSupportHelper
 **/
@isTest
public with sharing class CDdSupportHelperTest {

    public static final Id mxSxQId = [SELECT Id FROM Group WHERE DeveloperName = 'MxSx_Mx_Success_Associate' LIMIT 1].Id;

    @TestSetup
    static void setup(){
        Country_Mapping__c cm = new Country_Mapping__c();
        cm.Country__c = 'Germany';
        cm.Language__c = 'German';
        cm.Name = 'de';
        insert cm;

        //insert custom settings for mapping routing destination to queue Id
        Support_Assignment_Mapping__c mxSxQMapping = new Support_Assignment_Mapping__c();
        mxSxQMapping.Name = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Queue_Id__c = mxSxQId;
        mxSxQMapping.Support_Assignment_Name__c = CDdSupportConstants.MX_SUCCESS_ASSOCIATE;
        mxSxQMapping.Object__c = CDdSupportConstants.CASE_OBJECT_LABEL;
        insert mxSxQMapping;

        List<Customer_Segment_Mapping__c> lstCustomerSetting =new List<Customer_Segment_Mapping__c>();
        lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test1',Audience_Attribute_Number__c =98,Customer_Segment__c='Right Whale',Is_Active__c=true,Is_VIP__c=true));
        lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test2',Audience_Attribute_Number__c =94,Customer_Segment__c='Sei Whale',Is_Active__c=true,Is_VIP__c=true));
        lstCustomerSetting.add(new Customer_Segment_Mapping__c(Name='Test3',Audience_Attribute_Number__c =-1,Customer_Segment__c='Offender',Is_Active__c=true,Is_VIP__c=true));
        insert lstCustomerSetting;

        Queue_Mapping__c queueMapping = new Queue_Mapping__c();
        queueMapping.Is_Live_Queue__c = true;
        queueMapping.Queue_Id__c = mxSxQId;
        queueMapping.Queue_Usage__c = 'Active';
        insert queueMapping;
    }

    /**
     * @description Test method for getCountryMapping method
     */
    @isTest
    static void testGetCountryMapping(){
        Country_Mapping__c deCM = CDdSupportHelper.getCountryMapping('de');
        Country_Mapping__c defaultCM = CDdSupportHelper.getCountryMapping('ja');

        System.assertEquals(deCM.Country__c, 'Germany', 'Country on Country Mapping record is not same expected.');
        System.assertEquals(deCM.Language__c, 'German', 'Language on Country Mapping record is not same expected.');
        System.assertEquals(defaultCM.Country__c, 'United States', 'Default Country on Country Mapping record is not same expected.');
        System.assertEquals(defaultCM.Language__c, 'English', 'Default Language on Country Mapping record is not same expected.');
    }

    /**
     * @description Test method for createSendbirdEvent method
     */
    @isTest
    static void testCreateSendbirdEvent(){
        Case caseRecord = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        caseRecord.OwnerId = mxSxQId;
        Sendbird_Chat_Event__e sendbirdChatEvent = CDdSupportHelper.createSendbirdEvent(caseRecord, caseRecord);
        System.assertEquals(sendbirdChatEvent.Case_Id__c, caseRecord.Id, 'Id of case in Senbird Chat Platform Event is not same as expected.');
    }


    /**
     * @description Test method for createSendbirdMulesoftChatEvent method
     */
    @isTest
    static void testCreateSendbirdMulesoftChatEvent(){
        Case caseRecord = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        CDdSupportHelper.SendBirdChatEventWrapper wrapper = new CDdSupportHelper.SendBirdChatEventWrapper(caseRecord, caseRecord, false);
        Sendbird_Mulesoft_Chat_Event__e sendbirdChatEvent = CDdSupportHelper.createSendbirdMulesoftChatEvent(wrapper);
        System.assertEquals(sendbirdChatEvent.Case_Id__c, caseRecord.Id, 'Id of case in Senbird Chat Platform Event is not same as expected.');
    }

    /**
     * @description Test method for getSupportAssignmentRecordsByObject method
     */
    @isTest
    static void testGetSupportAssignmentRecordsByObject(){
        List<Support_Assignment_Mapping__c> supportAssignmentMappings = CDdSupportHelper.getSupportAssignmentRecordsByObject('Case');
        System.assert(supportAssignmentMappings.size() > 0, 'No Support Assignment Mapping record found.');
    }

    /**
     * @description Test method for getIdByRoutingDestination method
     */
    @isTest
    static void testGetIdByRoutingDestination(){
        List<Support_Assignment_Mapping__c> supportAssignmentMappings = CDdSupportHelper.getSupportAssignmentRecordsByObject('Case');
        String queueId = CDdSupportHelper.getIdByRoutingDestination(CDdSupportConstants.MX_SUCCESS_ASSOCIATE, supportAssignmentMappings);
        System.assertEquals(mxSxQId, queueId, 'Queue Id is not same as expected.');
    }

    /**
     * @description Test method for getObjToSupAssignList method
     */
    @isTest
    static void testGetObjToSupAssignList(){
        List<Support_Assignment_Mapping__c> supportAssignmentMappings = CDdSupportHelper.getObjToSupAssignList('Case');
        System.assert(supportAssignmentMappings.size() > 0, 'No Support Assignment Mapping record found.');
    }

    /**
     * @description Test method to check mapCustomerSegmentmapping and mapCustomerSegmentmapping variables
     */
    @isTest
    static void testMapCustomerSegmentmappingAndVips(){
        Map<Integer,String> mapCustomerSegmentmapping = CDdSupportHelper.mapCustomerSegmentmapping;
        List<Integer> lstVipNumbers = CDdSupportHelper.lstVipNumbers;
        System.assert(mapCustomerSegmentmapping.size() == 3, 'Number of Customer Segement Mapping is not same as expected.');
        System.assert(lstVipNumbers.contains(94), 'Vip Number is not same as expected.');
    }

    /**
     * @description Test method for isLiveQueue method
     */
    @isTest
    static void testIsLiveQueue(){
        Boolean isLiveQueue = CDdSupportHelper.isLiveQueue(mxSxQId);
        System.assert(isLiveQueue, 'Is Live Queue field on Queue Mapping record should be true.');
    }

    /**
     * @description Test method for isLiveOrderIssue method
     */
    @isTest
    static void testIsLiveOrderIssue(){
        Case caseRecord = TDdCaseFactory.createCaseRecords(1, 'Support')[0];
        caseRecord.Issue_Type__c = 'Start or Cancel/Unassign Order - Dx';
        caseRecord.Issue__c = 'Cancel + Unassign Order - Dx';
        Boolean isLiveOrderIssue = CDdSupportHelper.isLiveOrderIssue(caseRecord);
        System.assert(isLiveOrderIssue, 'Case does not have Live Order Issue and Issue Types');
    }
}