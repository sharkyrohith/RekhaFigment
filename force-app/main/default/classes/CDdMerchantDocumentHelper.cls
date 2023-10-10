/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 03/08/2021
*
* @group Merchant Document
*
* @description Merchant document related functions are defined here
* 
**************************************************************************************************************************************/
public class CDdMerchantDocumentHelper {
    /** 
     * Define variables here
     */
    public static final Boolean FEATURE_BUSINESS_VERIFICATION_DOCUMENT_ATTACH_ENABLED = CDdExperimentSvc.getFeatureFlag('Enable_Biz_Verification_Doc_Attach__c');
    public static final String BUSINESS_VERIFICATION_TYPE = 'Business Verification';
    public static Set<String> BUSINESS_VERIFICATION_SUB_TYPES;
    public static Set<String> BUSINESS_VERIFICATION_SUB_TYPES_REQUIRED_DOC_ID;
    public static boolean ranOpportunityUpdates = false;
    static {
        BUSINESS_VERIFICATION_SUB_TYPES = new Set<String>();
        BUSINESS_VERIFICATION_SUB_TYPES_REQUIRED_DOC_ID = new Set<String>();
        for (Business_Verification_Mx_Doc_Setting__mdt b : [SELECT Id, Type__c, Sub_Type__c, Is_Document_Id_Required__c 
                                                    FROM Business_Verification_Mx_Doc_Setting__mdt
                                                    WHERE Type__c = :BUSINESS_VERIFICATION_TYPE
                                                    ]){
            BUSINESS_VERIFICATION_SUB_TYPES.add(b.Sub_Type__c);
            if (b.Is_Document_Id_Required__c == true){
                BUSINESS_VERIFICATION_SUB_TYPES_REQUIRED_DOC_ID.add(b.Sub_Type__c);
            }
        }
    }    
    /**
     * Extract the Account Identifiers for the input Merchant Document records and return as a Collection
     */
    public static Set<Id> getAccountIds(List<Merchant_Document__c> merchantDocuments){
        Set<Id> accountIds = new Set<Id>();
        for (Merchant_Document__c md : merchantDocuments){
            accountIds.add(md.Merchant__c);
        }
        return accountIds;
    }   
    /** 
     * Filter accounts with Business Verifcation Document in place
     */
    public static Map<Id, Account> filterAccountsWithBusinessVerificationDocument(Set<Id> accountIds){
        Map<Id, Account> accountsWithBusinessVerificationDocuments = new Map<Id, Account>();
        for (Account a : [  SELECT Id, 
                            (   SELECT Type__c, Sub_Type__c, Merchant__c, File_URL__c, Document_ID__c 
                                FROM Merchant_Documents__r
                                WHERE Sub_Type__c IN :BUSINESS_VERIFICATION_SUB_TYPES
                                AND File_URL__c != null
                                AND (
                                    (Sub_Type__c NOT IN :BUSINESS_VERIFICATION_SUB_TYPES_REQUIRED_DOC_ID) 
                                    OR 
                                    (Sub_Type__c IN :BUSINESS_VERIFICATION_SUB_TYPES_REQUIRED_DOC_ID
                                    AND
                                    Document_ID__c != null)
                                )
                            )
                            FROM Account
                            WHERE Id IN :accountIds
                        ]){
            if (a.Merchant_Documents__r!=null && !a.Merchant_Documents__r.isEmpty()){
                accountsWithBusinessVerificationDocuments.put(a.Id, a);
            }                        
        }
        return accountsWithBusinessVerificationDocuments;
    }
    /**
     * Get the eligible Opportunity records to update for Business Verification Document
     * If the asscociated account has a Business Verification Dcoument in place
     *  - Set the field 'Business_Verification_Document_Attached__c' to true on the child Opportunties
     * Else
     *  - Set the field 'Business_Verification_Document_Attached__c' to false on the child Opportunties     * 
     */    
    public static List<Opportunity> getOpportunitiesToUpdateForBusinessVerificationDocument(Set<Id> accountIds){
        Map<Id, Account> accountsWithBusinessVerificationDocuments = filterAccountsWithBusinessVerificationDocument(accountIds);
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Account a : [  SELECT Id, 
                            (   SELECT Id, AccountId, Business_Verification_Document_Attached__c
                                FROM Opportunities)
                            FROM Account
                            WHERE Id IN :accountIds
                        ]){
            for (Opportunity o : a.Opportunities){
                Boolean isBusinessVerifiedDocumentAvailable = accountsWithBusinessVerificationDocuments.containsKey(o.AccountId);
                if (isBusinessVerifiedDocumentAvailable != o.Business_Verification_Document_Attached__c){
                    opportunitiesToUpdate.add(new Opportunity( 
                        Id = o.Id,
                        Business_Verification_Document_Attached__c = isBusinessVerifiedDocumentAvailable
                    ));
                }
            }
        }
        return opportunitiesToUpdate;        
    }
    /** 
     * Update Opportunty records for merchant document changes
     */    
    public static void updateOpportuntiesForMerchantDocumentChanges(List<Opportunity> opportunitiesToUpdate){
        if (ranOpportunityUpdates || (!FEATURE_BUSINESS_VERIFICATION_DOCUMENT_ATTACH_ENABLED && !Test.isRunningTest())){ return; }
        List<String> errorMessages = new List<String>();
        try {        
            if(!opportunitiesToUpdate.isEmpty()) {
                List<Database.SaveResult> sResults = Database.update(opportunitiesToUpdate, false);
                errorMessages = CDdErrorUtilities.processSaveResults(sResults, errorMessages);
                ranOpportunityUpdates = true;
            }
        } catch (Exception e) {
            CDdErrorUtilities.publishException('CDdMerchantDocumentHelper', 'updateOpportuntiesForMerchantDocumentChanges', e);
        } finally {
            CDdErrorUtilities.createApexLogs(errorMessages, 'CDdMerchantDocumentHelper', 'updateOpportuntiesForMerchantDocumentChanges', LoggingLevel.ERROR);
        }            
    }
    /** 
     * Handle updates to opportunty records for relevant merchant document changes on the parent account record
     */  
    public static void handleOpportunityUpdatesForBusinessVerificationDocument(List<Merchant_Document__c> merchantDocuments){
        Set<Id> accountIds = getAccountIds(merchantDocuments);
        List<Opportunity> opportuntiesToUpdate = getOpportunitiesToUpdateForBusinessVerificationDocument(accountIds);
        updateOpportuntiesForMerchantDocumentChanges(opportuntiesToUpdate);
    }
    /** 
     * Handle updates to opportunty records for accounts that possess merchant document(s)
     */  
    public static void handleOpportunityUpdatesForBusinessVerificationDocument(List<Generic_Platform_Event__e> events){
        Set<Id> accountIds = new Set<Id>();
        for (Generic_Platform_Event__e event : events) {
            accountIds.add(event.sObjectId__c);
        }        
        List<Opportunity> opportuntiesToUpdate = getOpportunitiesToUpdateForBusinessVerificationDocument(accountIds);
        updateOpportuntiesForMerchantDocumentChanges(opportuntiesToUpdate);
    }    
}