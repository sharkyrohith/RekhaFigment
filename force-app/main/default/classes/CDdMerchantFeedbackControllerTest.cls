/**
* @author Venkat D	
* @date 2022-02
*
* @description Test class for CDdMerchantFeedbackController
*/

@isTest
public class CDdMerchantFeedbackControllerTest {
    
    @TestSetup
    static void setup(){
        
        CDdContactTriggerHelper.insertCampaign();
        
        List<Account> accList = CDdTestDataFactory.createSObjectList('Account',1,false);
        insert accList;

        List<Contact> conList = CDdTestDataFactory.createSObjectList('Contact',1,false);
        conList[0].AccountId = accList[0].Id;
        insert conList;

        List<Opportunity> oppList =  CDdTestDataFactory.createSObjectList('Opportunity',1,false);
        oppList[0].AccountId = accList[0].Id;
        oppList[0].ContactId = conList[0].Id;
        insert oppList;
        
        List<Merchant_Feedback_Category__c> mfCategoryList = new List<Merchant_Feedback_Category__c>();
        Merchant_Feedback_Category__c mfCategory1 = new Merchant_Feedback_Category__c(Name='Dashpass',IsActive__c=true);
        Merchant_Feedback_Category__c mfCategory2 = new Merchant_Feedback_Category__c(Name='Caviar',IsActive__c=true);
        Merchant_Feedback_Category__c mfCategory3 = new Merchant_Feedback_Category__c(Name='Support',IsActive__c=true);
        mfCategoryList.add(mfCategory1);
        mfCategoryList.add(mfCategory2);
        mfCategoryList.add(mfCategory3);
        insert mfCategoryList;

        List<Merchant_Feedback_Reason__c> mfReasonList = new List<Merchant_Feedback_Reason__c>();
        Merchant_Feedback_Reason__c reason1 = new Merchant_Feedback_Reason__c(Name='Doesn\'t have certain functionality',IsActive__c=true);
        Merchant_Feedback_Reason__c reason2 = new Merchant_Feedback_Reason__c(Name='Data Issues',IsActive__c=true);
        Merchant_Feedback_Reason__c reason3 = new Merchant_Feedback_Reason__c(Name='DassPass too expensive',IsActive__c=true);
        mfReasonList.add(reason1);
        mfReasonList.add(reason2);
        mfReasonList.add(reason3);
        insert mfReasonList;
        
        List<Merchant_Feedback_Category_Reason__c> mfCategoryReasonList = new List<Merchant_Feedback_Category_Reason__c>();
        Merchant_Feedback_Category_Reason__c catReason1 = new Merchant_Feedback_Category_Reason__c(Merchant_Feedback_Category__c=mfCategoryList[0].Id,Merchant_Feedback_Reason__c=mfReasonList[0].Id);
        Merchant_Feedback_Category_Reason__c catReason2 = new Merchant_Feedback_Category_Reason__c(Merchant_Feedback_Category__c=mfCategoryList[0].Id,Merchant_Feedback_Reason__c=mfReasonList[2].Id);
        Merchant_Feedback_Category_Reason__c catReason3 = new Merchant_Feedback_Category_Reason__c(Merchant_Feedback_Category__c=mfCategoryList[1].Id,Merchant_Feedback_Reason__c=mfReasonList[0].Id);
        Merchant_Feedback_Category_Reason__c catReason4 = new Merchant_Feedback_Category_Reason__c(Merchant_Feedback_Category__c=mfCategoryList[2].Id,Merchant_Feedback_Reason__c=mfReasonList[1].Id);
        mfCategoryReasonList.add(catReason1);
        mfCategoryReasonList.add(catReason2);
        mfCategoryReasonList.add(catReason3);
        mfCategoryReasonList.add(catReason4);
        insert mfCategoryReasonList;


    }

    @isTest
    public static void testGetMerchantFeedbackCatagories(){
        
        Test.startTest();
        List<Merchant_Feedback_Category__c> mfCategories = CDdMerchantFeedbackController.getMerchantFeedbackCatagories();
        System.assertEquals(3, mfCategories.size());
        Test.stopTest();

    }

    @isTest
    public static void testGetFeedBackEntryWrapperList(){
        
        Test.startTest();
        
        List<String> categoryIds = new List<String>();
        List<Merchant_Feedback_Category__c> categorList = [Select Id,Name from Merchant_Feedback_Category__c WHERE IsActive__c = true];
        for(Merchant_Feedback_Category__c category:categorList){
            categoryIds.add(category.Id);
        }

        Account acct = [Select Id from Account Limit 1];
        List<CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper> wrapperList = CDdMerchantFeedbackController.getFeedBackEntryWrapperList(categoryIds,acct.Id,'Account');
        System.assertEquals(categorList.size(),wrapperList.size());

        Opportunity oppty = [Select Id from Opportunity Limit 1];
        wrapperList = CDdMerchantFeedbackController.getFeedBackEntryWrapperList(categoryIds,oppty.Id,'Opportunity');
        System.assertEquals(categorList.size(),wrapperList.size());

        Test.stopTest();
    }

    @isTest
    public static void testCreateMerchantFeedbackEntry(){

        Test.startTest();
        List<String> categoryIds = new List<String>();
		Map<Id,String> categoryReasonMap = new Map<Id,String>();
        
        List<Merchant_Feedback_Category__c> categorList = [Select Id,Name from Merchant_Feedback_Category__c WHERE IsActive__c = true];
        for(Merchant_Feedback_Category__c category:categorList){
            categoryIds.add(category.Id);
        }
        
        List<Merchant_Feedback_Category_Reason__c> feedbackActiveCategoryReasonList = [SELECT Merchant_Feedback_Reason__c,Merchant_Feedback_Reason__r.Name,Merchant_Feedback_Category__r.Name,Merchant_Feedback_Category__c 
                                                FROM Merchant_Feedback_Category_Reason__c 
                                                WHERE Merchant_Feedback_Category__c IN :categoryIds AND Merchant_Feedback_Reason__r.IsActive__c = TRUE];
        for(Merchant_Feedback_Category_Reason__c categoryReason:feedbackActiveCategoryReasonList){
            categoryReasonMap.put(categoryReason.Merchant_Feedback_Category__c,categoryReason.Merchant_Feedback_Reason__c);
        }
        
        
        
        String[] competetitors = new String[]{'GrubHub','Grab','Uber'};
            
        Account acct = [Select Id from Account Limit 1];
        List<CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper> wrapperList = CDdMerchantFeedbackController.getFeedBackEntryWrapperList(categoryIds,acct.Id,'Account');
        List<CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper> updatedWrapperList = new List<CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper>();
        for(CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper wrapper:wrapperList){
        	CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper updatedWrapper = new CDdMerchantFeedbackController.MerchantFeedbackEntryWrapper();
            updatedWrapper.selectedReason = categoryReasonMap.get(wrapper.feedbackEntry.Merchant_Feedback_Category__c);   
            updatedWrapper.status = 'Pitched';
            updatedWrapper.outcome = 'Interested';
            updatedWrapper.competitorSelected = competetitors;
         //   updatedWrapper.touchpoint = 'Sprint';
            updatedWrapper.sentiment = '1';
            updatedWrapper.notes = 'Test Notes';
            updatedWrapper.nextsteps = 'Test Next Steps';
            updatedWrapperList.add(updatedWrapper);
        }
        
        String touchpoint = 'Sprint';
        Date touchpointDate = System.today();
        String touchpointNotes = 'Touchpoint notes';
        String touchpointInteraction = 'Phone Call';

        String status = CDdMerchantFeedbackController.createMerchantFeedbackEntry(wrapperList,updatedWrapperList,touchpoint,touchpointDate,touchpointNotes,touchpointInteraction);
        List<Merchant_Feedback_Entry__c> mfeRecords = [SELECT Id from Merchant_Feedback_Entry__c WHERE Merchant_Feedback_Category__c IN :categoryIds];
        System.assertEquals(wrapperList.size(), mfeRecords.size());
		
        List<Merchant_Touchpoint__c> touchpointList = [SELECT Id,Account__c, Opportunity__c FROM Merchant_Touchpoint__c Limit 10];
        System.assertEquals(1, touchpointList.size());
        System.assertEquals(acct.Id, touchpointList[0].Account__c);
        
        Test.stopTest();
    }
}