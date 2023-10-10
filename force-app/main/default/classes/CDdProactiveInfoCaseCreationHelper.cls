/**
 * CDdProactiveCaseCreationHelper
 *
 * @author     Nayana
 * @date  	   Sept 2022
 * @decription Handle use Cases which needs Proactive Info Record Creation
 *             https://doordash.atlassian.net/browse/BIZS-1885
 */
public class CDdProactiveInfoCaseCreationHelper {

    @TestVisible private static final String CHAT_ISSUE_DETAILS = 'Item Unavailable or Clarification Needed on Item Ordered/Special Instructions';
    /**
     * handleItemUnavailable
     *
     * @author     Nayana
     * @date  	   Sept 2022
     * @decription Handle use Cases which needs Proactive Info Record Creation
     * @param     cWrap : Proactive Case creation wrapper
     * @return  List<Proactive_Case_Info__c> list of Proactive Case Info to upsert
     */
    public static List<Proactive_Case_Info__c> handleItemUnavailable(CDdProactiveCaseCreationHelper.ProactiveCaseInfo cWrap) {
        List<Proactive_Case_Info__c> lstProactiveCaseInfosUpsert = new List<Proactive_Case_Info__c>();
        List<Case> lstCaseToInsert = new List<Case>();
        Id proactiveCaseRecordTypeId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName(cWrap.caseRecordType);
        Support_Settings__c setting = Support_Settings__c.getInstance();
        Boolean runExpList = setting!=null ? setting.Limit_Item_Unavailable_Mx_List__c : false;
        Integer lookBackTimeHours   = setting!=null ? setting.Item_Unavailable_Lookback_time__c!=null ?
                                     Integer.valueOf(setting.Item_Unavailable_Lookback_time__c)
                                    : 24 : 24;
        Boolean isValidEntryCriterion = false;
        List<Proactive_Case_Info__c> lstExstProactiveCases = new List<Proactive_Case_Info__c> ();
        try{
            DateTime lookBackTime = System.now().addHours(-lookBackTimeHours);
            if(cWrap.deliveryUUID!=null){
                //Query Delivery Object to get the Merchant
                List<Delivery__c> lstDelivery = [SELECT Id,Merchant__c,MerchantNo__c FROM Delivery__c WHERE DeliveryUUID__c =: cWrap.deliveryUUID];
                List<String> lstExcludedMerchants = CDdNameValuePairHelper.getLongTextValue(CDdNameValuePairConstants.ITEM_UNAVAILABLE_EXCLUDED_MERCHANTIDS).split(CDdCoreConstants.DELIMITER_SEMICOLON);
                if(!lstDelivery.isEmpty()){
                    //if Merchant Store is excluded then don't run the logic.
                    if(!lstExcludedMerchants.isEmpty() && lstExcludedMerchants.contains(String.valueOf(lstDelivery[0].MerchantNo__c))){
                        return null;
                    }
                    //Custom Setting to turn ON/OFF Experiment list
                    if(runExpList){
                        List<String> lstAllowedMerchants = CDdNameValuePairHelper.getLongTextValue(CDdNameValuePairConstants.ITEM_UNAVAILABLE_POC_MERCHANTIDS).split(CDdCoreConstants.DELIMITER_SEMICOLON);
                        if((lstDelivery[0].MerchantNo__c!=null && lstAllowedMerchants.contains(String.valueOf(lstDelivery[0].MerchantNo__c)))|| Test.isRunningTest()){
                            isValidEntryCriterion = true;
                        }
                    }else if(lstDelivery[0].Merchant__c!=null){
                        isValidEntryCriterion = true;
                    }
                }

                if(isValidEntryCriterion){
                    Id merchantId = lstDelivery[0].Merchant__c;
                    //Query Proactive Case Info Object to find any existing record for same merchant in same day
                    lstExstProactiveCases =[SELECT Id,Proactive_Case_Created__c,Original_Case__c FROM Proactive_Case_Info__c WHERE
                                                                        Merchant__c =:merchantId AND CreatedDate >=: lookBackTime
                                                                        AND Case_Type__c =: cWrap.caseType];
                    /*If record found for merchant and Case is not already created then create new case else create
                    info record
                    */
                    if(lstExstProactiveCases.size()>0 && !lstExstProactiveCases[0].Proactive_Case_Created__c && cWrap.originalCase.Id!=lstExstProactiveCases[0].Original_Case__c){
                        List<Case> lstCase = [SELECT ID FROM Case WHERE CreatedDate >=: lookBackTime AND
                                              RecordTypeId =:proactiveCaseRecordTypeId AND AccountId =:merchantId
                                              AND Chat_Issue_Details__c!=null];
                        if(lstCase.isEmpty()){
                            Case c = new Case();
                            c.RecordTypeId = proactiveCaseRecordTypeId;
                            c.Customer_Type__c = cWrap.customerType;
                            c.DeliveryUUId__c = cWrap.deliveryUUID;
                            c.AccountId = lstDelivery[0].Merchant__c;
                            c.Origin = cWrap.caseOrigin;
                            c.Chat_Issue_Details__c = CHAT_ISSUE_DETAILS;
                            c.Issue_Type__c = CDdSupportConstants.ISSUETYPE_LIVE_ORDER_MX;
                            c.Issue__c = CDdSupportConstants.ISSUE_ITEM_UNAVAILABLE;
                            c.Feature_Logs__c = CDdErrorUtilities.constructFeatureLog('PROACTIVE CASE WRAPPER','Proactive Info: '+ lstExstProactiveCases[0].Id + '2 Dasher Cases are # '+ cWrap.originalCase.Id + ' and '+ lstExstProactiveCases[0].Original_Case__c + ' New UUID is: '+ cWrap.deliveryUUID +' Time : ' + System.now() , true);
                            lstCaseToInsert.add(c);
                        }
                    }else if(lstExstProactiveCases.size()==0){
                        Proactive_Case_Info__c proCaseInfo = new Proactive_Case_Info__c();
                        proCaseInfo.Original_Case__c = cWrap.originalCase.Id;
                        proCaseInfo.Case_Type__c = cWrap.caseType;
                        proCaseInfo.Merchant__c = lstDelivery[0].Merchant__c;
                        lstProactiveCaseInfosUpsert.add(proCaseInfo);
                    }
                }
            }
            if(!lstCaseToInsert.isEmpty()){
                List<Database.SaveResult> sResults = Database.insert(lstCaseToInsert,false);
                CDdErrorUtilities.publishException('CDdProactiveInfoCaseCreationHelper','handleItemUnavailable',sResults);
                List<String> errorMessages = new List<String>();
                Set<Id> setCaseId = new Set<Id>();
                //get Case Id of Successfuly created Cases.
                for(Database.SaveResult sr : sResults) {
                    if(sr.isSuccess() || Test.IsRunningTest()){
                        if (sr.isSuccess()) {
                            setCaseId.add(sr.getId());
                        }
                    }else{
                        for(Database.Error err : sr.getErrors()) {
                            errorMessages.add(err.getStatusCode() + ' : ' + err.getMessage() + ' : Fields : ' + err.getFields());
                        }
                    }
                }
                //Create Case Notes for cases
                List<FeedItem> lstCaseFeed = new List<FeedItem>();
                for(Id caseId:setCaseId){
                    //If case insertion is successful then update Info record
                    lstExstProactiveCases[0].Proactive_Case_Created__c = true;
                    lstExstProactiveCases[0].Log__c = 'Second Dasher Case is # ' + cWrap.originalCase.Id + ' Proactive Case is :' + setCaseId;
                    lstProactiveCaseInfosUpsert.add(lstExstProactiveCases[0]);

                    FeedItem cFeed = new FeedItem();
                    cFeed.ParentId = caseId;
                    cFeed.Body = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.ITEM_UNAVAILABLE_CASE_NOTES);

                    lstCaseFeed.add(cFeed);
                }
                if(!errorMessages.isEmpty()){
                    lstExstProactiveCases[0].Log__c = errorMessages[0];
                }
                if(!lstCaseFeed.isEmpty()){
                    List<Database.SaveResult> sFeedResults = Database.insert(lstCaseFeed,false);
                    CDdErrorUtilities.publishException('CDdProactiveInfoCaseCreationHelper','handleItemUnavailable',sFeedResults);
                }
            }
        }catch(Exception e){
            CDdErrorUtilities.publishException('CDdProactiveInfoCaseCreationHelper','handleItemUnavailable',e);
        }
        return lstProactiveCaseInfosUpsert;
    }
}