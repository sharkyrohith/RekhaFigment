/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/15/2020
*
* @group SObject Field Copy
*
* @description Test class for SObject Copy Config Object
* 
**************************************************************************************************************************************/
@isTest
public with sharing class CDdSObjectCopyConfigObjTest {
    private static final String SOBJECT_TYPE_ACCOUNT = 'Account';
    private static final String SOBJECT_TYPE_CONTACT = 'Contact';
    private static final String SOBJECT_TYPE_LEAD = 'Lead';    
    private static final String SOBJECT_TYPE_OPPORTUNITY = 'Opportunity';   
    /**
    * @description Test for batch size retrieval
    */
    @isTest 
    public static void testGetBatchSize(){
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_ACCOUNT)>0, 'Expecting a valid batch size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_CONTACT)>0, 'Expecting a valid batch size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_LEAD)>0, 'Expecting a valid batch size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getBatchSize(SOBJECT_TYPE_OPPORTUNITY)>0, 'Expecting a valid batch size');
    }
    /**
    * @description Test for threshold size retrieval
    */
    @isTest 
    public static void testGetThresholdSize(){
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_ACCOUNT)>0, 'Expecting a valid threshold size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_CONTACT)>0, 'Expecting a valid threshold size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_LEAD)>0, 'Expecting a valid threshold size');
        System.assertEquals(true, new CDdSObjectCopyConfigObj().getThresholdSize(SOBJECT_TYPE_OPPORTUNITY)>0, 'Expecting a valid threshold size');
    }
}