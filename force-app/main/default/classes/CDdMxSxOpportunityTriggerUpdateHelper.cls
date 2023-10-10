/********************************************************************************************************************
* @author Lathika
* @date 11/11/2022
*
* @group Merchant Services
*
* @description Opportunity trigger helper class that sets the before insert and Update values
*
**************************************************************************************************************************************/
public class CDdMxSxOpportunityTriggerUpdateHelper {

    public static Boolean ranSetPDOADate = false;
    public static Boolean ranSetPDOMDate = false;
    public static final String MENU_UI_TYPE_RETAIL = 'Retail';
    public static Map<Id, Business_Vertical__c> BUSINESS_VERTICAL_MAP = CDdAccountHelperMethods.BUSINESS_VERTICAL_MAP;

    /**
     * @description sets the values on the Opportunity on Before Insert and Before Update context
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return
    */
    public void applyUpdates(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts){
        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity newObj :newList){
            if( CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId)){
                opportunityIds.add(newObj.Id);
            }
        }
        if(opportunityIds.isEmpty()){
            return;
        }
        setPDOADate(newList, oldMap, accounts);
        setPDOMDate(newList, oldMap);
    }
    /**
     * @author Veera
     * @date 2022-12-02
     * @description PDOA Date is set for the following conditions
     * 1. COO (Enterprise Marketplace or Marketplace)
     * 2. Marketplace (SMB)
     */
    private void setPDOADate(List<Opportunity> newList, Map<Id, Opportunity> oldMap,  Map<Id, Account> accounts) {
        if(ranSetPDOADate){ return; }
        for (Opportunity newOpp: newList) {
            Opportunity oldOpp ;
            if (oldMap != null) {
                oldOpp = oldMap.get(newOpp.Id);
            }

            if(CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newOpp.StageName)){
                Boolean isOpptyProcessed = false;
                if(CDdMxSxOpportunityHelper.isOpportunityofTypeChangeofOwnership(newOpp)){
                    isOpptyProcessed = setPDOAForCOOOpportunities(newOpp, oldOpp);
                }
                if(!isOpptyProcessed && CDdMxSxOpportunityHelper.isSMB(newOpp)){
                    isOpptyProcessed = setPDOAForMarketplaceOpportunities(newOpp, oldOpp, accounts);
                }
            }
        }
        ranSetPDOADate = true;
    }
    /**
     * @author Veera
     * @date 2022-12-02
     * @description PDOA Date is set for the following conditions
     * 1. COO (Enterprise Marketplace or Marketplace)
     * 2. Enterprise Marketplace
     */
    private void setPDOMDate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if(ranSetPDOMDate){ return; }
        for (Opportunity newOpp: newList) {
            Opportunity oldOpp ;
            if (oldMap != null) {
                oldOpp = oldMap.get(newOpp.Id);
            }

            if(CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newOpp.StageName)){
                Boolean isOpptyProcessed = false;
                if(CDdMxSxOpportunityHelper.isOpportunityofTypeChangeofOwnership(newOpp)){
                    isOpptyProcessed = setPDOMForCOOOpportunities(newOpp, oldOpp);
                }
                if(!isOpptyProcessed && CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_ENTERPRISE_MARKETPLACE.equals(newOpp.RecordTypeId)){
                    isOpptyProcessed = setPDOMForEnterpriseOpportunities(newOpp, oldOpp);
                }
            }
        }
        ranSetPDOMDate = true;
    }
    /**
     * @author Veera
     * @date 2022-12-02
     * @description BZAP-18132, Set PDOA when Opp Type Equal to 'Change of Ownership'
     * PDOA Date is set for the following conditions
     * 1. If there is change in Onwership (Change_of_Ownership_Effective_Date__c)
     *  COOED is greater than or equal to 5 business days greater than CW date, assign COOED as PDOA. Subtract 1 business day from PDOA to set PDOM.
     *  COOED is less than or equal to 4 business days greater than CW date, assign PDOM as 4 business days from CW days. Assign PDOA as the following business day from PDOM.
     * Original Ticket: BZAP-6970 - Moved the logic from workslow rule https://figment.my.salesforce.com/01Q2L0000001tcM
     * @param Opportunity new Opportunity records
     * @param Opportunity old Opportunity records (applied to update trigger events)
     * @return Boolean return true if Opportunity PDOA date is updated
     */
    private Boolean setPDOAForCOOOpportunities(Opportunity newOpp , Opportunity oldOpp) {
        Boolean isOpptyProcessed = false;
        switch on (CDdMxSxConstants.getMxSxOpportunityPlatform(newOpp.Platform__c)) {
            when CAVIAR, CAVIAR_AND_DOORDASH {
                if (CDdMxSxTriggerHelper.hasFieldValueChanged(newOpp, oldOpp, 'StageName')){
                    newOpp.Proposed_Date_of_Activation__c = CDdMxSxConstants.MXSX_OPPORTUNITY_CAVIAR_ORDER_PROTOCOL_POS.contains(newOpp.Order_Protocol__c) ? newOpp.CloseDate.addDays(14) : newOpp.CloseDate.addDays(7);
                    isOpptyProcessed = true;
                }
            }
            when DOORDASH {
                if (isChangeOfOwnership(newOpp, oldOpp)){
                    newOpp.Proposed_Date_of_Activation__c = (newOpp.Change_of_Ownership_Effective_Date__c >= CDdMxSxConstants.addBusinessDays(newOpp.CloseDate, 5)) ? newOpp.Change_of_Ownership_Effective_Date__c : CDdMxSxConstants.addBusinessDays(newOpp.CloseDate, 5);              
                    isOpptyProcessed = true;
                }
            }
        }
        return isOpptyProcessed;
    }
    /**
     * @author Lathika
     * @date 2022-10-24
     * @description BZAP-17940, Set PDOA of SMB Merchants && Opp Type Not Equal to 'Change of Ownership'
     * COO Opportunities have a different Logic to Set PDOA
     * IF PDOA = null:
     *  PDOA date = CloseWon Date + 21(for Retail Merchants)
     *  PDOA date = CloseWon Date + 10
     *  PDOA date = CloseWon Date + 14 (if Order Protocol contains POS)
     * if PDOA date falls on a weekend, assign to following working day
     * @param Opportunity new Opportunity records
     * @param Opportunity old Opportunity records (applied to update trigger events)
     * @return Boolean return true if Opportunity PDOA date is updated
     */
    private Boolean setPDOAForMarketplaceOpportunities(Opportunity newOpp, Opportunity oldOpp,  Map<Id, Account> accounts) {
        Boolean isOpptyProcessed = false;
        Boolean isPOS = newOpp.Order_Protocol__c != null && newOpp.Order_Protocol__c.contains('POS');
        Account account = String.isNotBlank(newOpp.AccountId) && accounts.containsKey(newOpp.AccountId) ? accounts.get(newOpp.AccountId) : null;
        String  accDeckRabk = (account != null && account.Deck_Rank__c != null) ? account.Deck_Rank__c : null;
        String  accLaunchDeckRank = (account != null && account.Launch_Deck_Rank__c != null) ? account.Launch_Deck_Rank__c : null;
        Id businessVerticalId = (account.ParentId != null ? account.Parent.Business_Vertical__c : null);
        Boolean isRetail = (businessVerticalId != null) && BUSINESS_VERTICAL_MAP.containsKey(businessVerticalId) && MENU_UI_TYPE_RETAIL.equals(BUSINESS_VERTICAL_MAP.get(businessVerticalId).Menu_UI_Type__c);
        ID accountRecordTypeID = (account != null && account.RecordTypeId != null) ? account.RecordTypeId : null;
        if (CDdMxSxOpportunityHelper.isSMB(newOpp)
            && !CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(accountRecordTypeID)
            && !CDdMxSxConstants.DECK_RANKS_TO_EXCLUDE_FOR_SMB.contains(accLaunchDeckRank)
            && !CDdMxSxConstants.DECK_RANKS_TO_EXCLUDE_FOR_SMB.contains(accDeckRabk)
            && !CDdMxSxOpportunityHelper.isOpportunityofTypeChangeofOwnership(newOpp)
            && newOpp.Proposed_Date_of_Activation__c == null
            && CDdMxSxTriggerHelper.hasFieldValueChanged(newOpp, oldOPP, 'StageName')){
                if (isRetail){
                    newOpp.Proposed_Date_of_Activation__c = newOpp.CloseDate + 21;
                } else if (isPOS) {
                    newOpp.Proposed_Date_of_Activation__c = newOpp.CloseDate + 14;
                } else {
                    newOpp.Proposed_Date_of_Activation__c = newOpp.CloseDate + 10;
                }
                isOpptyProcessed = true;
        }
        return isOpptyProcessed;
    }
    /**
     * @author Veera
     * @date 2022-12-01
     * @description BZAP-18132, Set PDOM when Opp Type Equal to 'Change of Ownership'
     * Moved the logic from workslow rule https://figment.my.salesforce.com/01Q2L0000001tcM
     * IF PDOM = null: Set it to Today + 4 days
     * if Change_of_Ownership_Effective_Date__c != null --> Set it to PDOA - 1
     * @param Opportunity new Opportunity records
     * @param Opportunity old Opportunity records (applied to update trigger events)
     * @return Boolean return true if Opportunity PDOM date is updated
     */
    private Boolean setPDOMForCOOOpportunities(Opportunity newOpp, Opportunity oldOpp) {
        Boolean isOpptyProcessed = false;
        switch on (CDdMxSxConstants.getMxSxOpportunityPlatform(newOpp.Platform__c)) {
            when CAVIAR, CAVIAR_AND_DOORDASH {
                if (CDdMxSxTriggerHelper.hasFieldValueChanged(newOpp, oldOpp, 'StageName')){
                    newOpp.Proposed_Date_of_Menu__c = CDdMxSxConstants.MXSX_OPPORTUNITY_CAVIAR_ORDER_PROTOCOL_POS.contains(newOpp.Order_Protocol__c) ? newOpp.CloseDate.addDays(13) : newOpp.CloseDate.addDays(6);
                    isOpptyProcessed = true;
                }
            }
            when DOORDASH {
                if (isChangeOfOwnership(newOpp, oldOpp)){
                    newOpp.Proposed_Date_of_Menu__c = (newOpp.Change_of_Ownership_Effective_Date__c.addDays(-1) >= CDdMxSxConstants.addBusinessDays(newOpp.CloseDate, 4)) ? newOpp.Change_of_Ownership_Effective_Date__c.addDays(-1) : CDdMxSxConstants.addBusinessDays(newOpp.CloseDate, 4);
                    isOpptyProcessed = true;
                } 
            }
        }               
        return isOpptyProcessed;
    }
    /**
     * @author Veera
     * @date 2022-12-01
     * @description BZAP-18132, Set PDOM when Opportunity is Enterprise Marketplace
     * Moved the logic from workslow rule https://figment.my.salesforce.com/01Q2L0000001tcM
     * IF PDOM = null: Set it to Today + 4 Business days
     * if Change_of_Ownership_Effective_Date__c != null --> Set it to PDOA - 1
     * @param Opportunity new Opportunity records
     * @param Opportunity old Opportunity records (applied to update trigger events)
     * @return Boolean return true if Opportunity PDOM date is updated
     */
    private Boolean setPDOMForEnterpriseOpportunities(Opportunity newOpp, Opportunity oldOpp) {
        Boolean isOpptyProcessed = false;
        if (newOpp.Proposed_Date_of_Menu__c == null){
            newOpp.Proposed_Date_of_Menu__c = CDdMxSxConstants.addBusinessDays(Date.today(), 4); 
            newOpp.PB_WF_Flow_Ran__c = 'Set PDOM WF Ran';
            isOpptyProcessed = true;
        }
        return isOpptyProcessed;
    }
    /**
     * @author Veera
     * @date 2022-12-01
     * @description BZAP-18132, determines the If there is change in 'Change of Ownership'
     * @param Opportunity new Opportunity records
     * @param Opportunity old Opportunity records (applied to update trigger events)
     * @return
     */
    private static Boolean isChangeOfOwnership(Opportunity newOpp, Opportunity oldOpp) {
        return newOpp.Change_of_Ownership_Effective_Date__c != null
            && (CDdMxSxTriggerHelper.hasFieldValueChanged(newOpp, oldOpp, 'StageName')
                || CDdMxSxTriggerHelper.hasFieldValueChanged(newOpp, oldOpp, 'Change_of_Ownership_Effective_Date__c'));
    }

}