/**
* @author: Venkat
* @date: 2022-02
* @ This class fetches Merchant Feedback Category, Merchant Feedback Category Reaon and creates Merchant Feedback Entry (MFE) records.
*/
public with sharing class CDdMerchantFeedbackController {

    // Return active Merchant_Feedback_Category__c records where there is an entry in Merchant_Feedback_Category_Reason__c object.
    @AuraEnabled(cacheable=true)
    public static List<Merchant_Feedback_Category__c> getMerchantFeedbackCatagories() {
        return [
            SELECT Id,Name FROM Merchant_Feedback_Category__c
            WHERE IsActive__c = true AND Id IN (Select Merchant_Feedback_Category__c FROM Merchant_Feedback_Category_Reason__c)
            ORDER BY Name ASC
        ];
    }

    // Return active Merchant_Feedback_Category__c records where there is an entry in Merchant_Feedback_Category_Reason__c object.
    @AuraEnabled(cacheable=true)
    public static List<MerchantFeedbackEntryWrapper> getFeedBackEntryWrapperList(List<String> categoryIds,Id recId,String objectName) {

        Id accountId;
        Id opportunityId;
        List<PicklistWrapper> opportunityList = new List<PicklistWrapper>();

        if(objectName == 'Account'){
            List<Merchant_Feedback_Setting__mdt> opportunityFilterSetting = [SELECT Id, MasterLabel, DeveloperName,Start_Date__c,End_Date__c FROm Merchant_Feedback_Setting__mdt WHERE DeveloperName = 'Opportunity_Date_Filter'];

            accountId = recId;
            Account accountRecord = [SELECT Id,ParentId FROM Account WHERE Id = :accountId];
            List<Opportunity> opptyList = new List<Opportunity>();
            if(opportunityFilterSetting != null && !opportunityFilterSetting.isEmpty() && opportunityFilterSetting[0].Start_Date__c != null && opportunityFilterSetting[0].End_Date__c != null && !Test.isRunningTest()){
                opptyList = [SELECT Id,Name FROM Opportunity WHERE (AccountId = :accountId OR AccountId = :accountRecord.ParentId) AND CreatedDate >= :opportunityFilterSetting[0].Start_Date__c AND CreatedDate <= :opportunityFilterSetting[0].End_Date__c];
            }else{
                opptyList = [SELECT Id,Name FROM Opportunity WHERE (AccountId = :accountId OR AccountId = :accountRecord.ParentId) AND CreatedDate = THIS_FISCAL_QUARTER];
            }
            
            for(Opportunity oppty : opptyList){
                opportunityList.add(new PicklistWrapper(oppty.Name,oppty.Id));
            }
        }else if(objectName == 'Opportunity'){
            Opportunity oppty = [SELECT Id,Name,AccountId from Opportunity Where Id = :recId];
            accountId = oppty.AccountId;
            opportunityId = oppty.Id;
            opportunityList.add(new PicklistWrapper(oppty.Name,oppty.Id));
        }

        List<MerchantFeedbackEntryWrapper> wrapperList = new List<MerchantFeedbackEntryWrapper>();
        Map<String,MerchantFeedbackEntryWrapper> categoryWrapperMap = new Map<String,MerchantFeedbackEntryWrapper>();

        List<Merchant_Feedback_Category_Reason__c> feedbackActiveCategoryReasonList = [SELECT Merchant_Feedback_Reason__c,Merchant_Feedback_Reason__r.Name,Merchant_Feedback_Category__r.Name,Merchant_Feedback_Category__c
                                                FROM Merchant_Feedback_Category_Reason__c
                                                WHERE Merchant_Feedback_Category__c IN :categoryIds AND Merchant_Feedback_Reason__r.IsActive__c = TRUE];

        Integer indexValue = 0;
        for(Merchant_Feedback_Category_Reason__c categoryReason:feedbackActiveCategoryReasonList){

            if(categoryWrapperMap.containsKey(categoryReason.Merchant_Feedback_Category__c)){
                MerchantFeedbackEntryWrapper wrapper = categoryWrapperMap.get(categoryReason.Merchant_Feedback_Category__c);
                wrapper.addReason(categoryReason.Merchant_Feedback_Reason__r.Name, categoryReason.Merchant_Feedback_Reason__c);
            }else{
                Merchant_Feedback_Entry__c feedbackEntry = new Merchant_Feedback_Entry__c();
                feedbackEntry.Merchant_Feedback_Category__c = categoryReason.Merchant_Feedback_Category__c;
                feedbackEntry.Account__c = accountId;
                feedbackEntry.Opportunity__c = opportunityId;

                MerchantFeedbackEntryWrapper wrapper = new MerchantFeedbackEntryWrapper(categoryReason.Merchant_Feedback_Category__r.Name,feedbackEntry,indexValue++);
                wrapper.addReason(categoryReason.Merchant_Feedback_Reason__r.Name, categoryReason.Merchant_Feedback_Reason__c);
                categoryWrapperMap.put(categoryReason.Merchant_Feedback_Category__c, wrapper);
                wrapper.opportunities = opportunityList;
                wrapperList.add(wrapper);
            }

        }

        return wrapperList;
    }

    @AuraEnabled
    public static String createMerchantFeedbackEntry(List<MerchantFeedbackEntryWrapper> wrapperList,List<MerchantFeedbackEntryWrapper> updatedWrapperList,String touchPoint,Date touchpointDate,String touchpointNotes,String touchpointInteraction){

        Merchant_Touchpoint__c merchantTouchPoint = new Merchant_Touchpoint__c(Touchpoint__c=touchPoint,Touchpoint_Date__c = touchpointDate,Notes__c = touchpointNotes,Touchpoint_Interaction__c=touchpointInteraction);
        Id accountId = null;
        Id opportunityId = null;
        for(MerchantFeedbackEntryWrapper wrapper:wrapperList){
            if(wrapper.feedbackEntry != null){
                if(accountId == null && wrapper.feedbackEntry.Account__c != null){
                    accountId = wrapper.feedbackEntry.Account__c;
                    opportunityId = wrapper.feedbackEntry.Opportunity__c;
                    break;
                }
            }
        }
        merchantTouchPoint.Account__c = accountId;
        merchantTouchPoint.Opportunity__c = opportunityId;
        insert merchantTouchPoint;

        List<String> opptyIdList = new List<String>();
        List<Merchant_Feedback_Entry__c> mfeList =  new List<Merchant_Feedback_Entry__c>();
        for(Integer index=0;index<updatedWrapperList.size();index++){
            MerchantFeedbackEntryWrapper updatedWrapper = updatedWrapperList[index];
            if(String.isNotBlank(updatedWrapper.selectedReason)){
                Merchant_Feedback_Entry__c feedbackEntry = wrapperList[index].feedbackEntry;
                feedbackEntry.Merchant_Feedback_Reason__c = updatedWrapper.selectedReason;
                feedbackEntry.Status__c = updatedWrapper.status;
                feedbackEntry.Outcome__c = updatedWrapper.outcome;
                feedbackEntry.Sentiment__c = updatedWrapper.sentiment;
                feedbackEntry.Notes__c = updatedWrapper.notes;
                feedbackEntry.Next_Steps__c = updatedWrapper.nextsteps;
                feedbackEntry.Merchant_Touchpoint__c = merchantTouchPoint.Id;
                if(updatedWrapper.competitorSelected != null && updatedWrapper.competitorSelected.size() > 0){
                    feedbackEntry.Competitors__c = String.join( updatedWrapper.competitorSelected, ';');
                }
                feedbackEntry.Opportunity__c = updatedWrapper.selectedOppty;
                opptyIdList.add(feedbackEntry.Opportunity__c);
                mfeList.add(feedbackEntry);

            }
        }

        Map<Id,Opportunity> opportunityMap = new Map<Id,Opportunity>([Select Id,StageName from Opportunity Where Id in :opptyIdList]);
        for(Merchant_Feedback_Entry__c mfe:mfeList){
            mfe.Opportunity_Stage_Name__c = opportunityMap.get(mfe.Opportunity__c)?.StageName;
        }
        if(!mfeList.isEmpty()){
            Database.SaveResult[] insertResult = Database.insert(mfeList,false);
        }
        return 'Success';
    }

    // wrapper class for Queue Manager initialization
    public class MerchantFeedbackEntryWrapper {
        @auraEnabled
        public Merchant_Feedback_Entry__c feedbackEntry {get; set;}
        @auraEnabled
        public String category {get; set;}
        @auraEnabled
        public List<PicklistWrapper> reasons {get; set;}

        @auraEnabled
        public Integer keyValue {get; set;}

        @auraEnabled
        public String selectedReason{get; set;}
        @auraEnabled
        public String status {get; set;}
        @auraEnabled
        public String outcome {get; set;}
        @auraEnabled
        public String[] competitorSelected {get; set;}
        @auraEnabled
        public String competitors {get; set;}
        @auraEnabled
        public String touchpoint  {get; set;}
        @auraEnabled
        public String sentiment  {get; set;}
		@auraEnabled
        public String notes  {get; set;}
        @auraEnabled
        public String nextsteps {get; set;}
		@auraEnabled
        public String reason {get; set;}
        @auraEnabled
        public List<PicklistWrapper> opportunities {get; set;}
        @auraEnabled
        public String selectedOppty {get; set;}


        public MerchantFeedbackEntryWrapper(){

        }
        public MerchantFeedbackEntryWrapper(String category,Merchant_Feedback_Entry__c feedbackEntry,Integer keyValue) {
            this.category = category;
            this.selectedReason = null;
            this.feedbackEntry = feedbackEntry;
            this.reasons = new List<PicklistWrapper>();
            this.keyValue = keyValue;
        }

        public void addReason(String reason, String Id){
            reasons.add(new PicklistWrapper(reason,Id));
        }
    }

    public class PicklistWrapper{
        @auraEnabled
        public String label {get; set;}
        @auraEnabled
        public String value {get; set;}

        public PicklistWrapper(){

        }
        public PicklistWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }
}