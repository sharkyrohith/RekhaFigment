/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 11/09/2020
*
*
* @group Opportunity Line Item Validation
*
* @description Helper class to perform validation on Opportunity and related Opportunity Products 
**********************************************************************************************************************/
public class CDdOpportunityLineItemValidationHelper {
    public static Boolean RAN_VALIDATION_ONCE = false;
    public static Id doorDashForBusinessRecTypeId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId();
    public static final String PAYMENT_PROTOCOL_INVOICING = 'Invoicing';
    /**
     * @description: Private method to group line items by opportunity Id
     */ 
    private static Map<Id, List<OpportunityLineItem>> getOpportunityLineItemsByOppId(List<OpportunityLineItem> opportunityLineItems){
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem opportunityLineItem : opportunityLineItems){
            if (opportunityLineItemsByOppId.containsKey(opportunityLineItem.OpportunityId)){
                opportunityLineItemsByOppId.get(opportunityLineItem.OpportunityId).add(opportunityLineItem);
            } else {
                opportunityLineItemsByOppId.put(opportunityLineItem.OpportunityId, new List<OpportunityLineItem>{opportunityLineItem});
            } 
        }
        return opportunityLineItemsByOppId;        
    }
    /**
     * @description: Return the following collection
     *  Build a map of 
     *  Level 0 - Opportunity Id => Collection of oli grouped by Pricebook Entry Id
     *  Level 1 - Pricebook Entry Id => Collection of Opportunity Line Items (olis)
     * @param opportunities - Opportunities queried from DB along with sub-query of child line items     
     */     
    private static Map<Id, Map<Id, List<OpportunityLineItem>>> getLineItemsByPricebookEntryIdByOppId(Map<Id, Opportunity> opportunities, List<OpportunityLineItem> opportunityLineItems){
        // Build a Collection of updated Opportunity Line Items with unique oli record Ids received as input
        Map<Id, OpportunityLineItem> updatedOpportunityLineItems = new Map<Id, OpportunityLineItem>();
        for (OpportunityLineItem oli : opportunityLineItems){
            // Populated only if the oli is an updated record and not a new record
            if (String.isNotBlank(oli.Id)){
                updatedOpportunityLineItems.put(oli.Id, oli);
            }
        }        
        // Build a map of 
        // Level 0 - Opportunity Id => Collection of oli grouped by Pricebook Entry Id
        // Level 1 - Pricebook Entry Id => Collection of Opportunity Line Items (olis)
        Map<Id, Map<Id, List<OpportunityLineItem>>> lineItemsByPricebookEntryIdByOppId = new Map<Id, Map<Id, List<OpportunityLineItem>>>();
        // Process oli records found in DB but not found in collection updatedOpportunityLineItems         
        for (Opportunity opp : opportunities.values()){
            Map<Id, List<OpportunityLineItem>> lineItemsByPricebookEntryId = new Map<Id, List<OpportunityLineItem>>();
            for (OpportunityLineItem oli : opp.OpportunityLineItems){
                if (!updatedOpportunityLineItems.containsKey(oli.Id)){
                    if (String.isNotBlank(oli.PricebookEntryId)){
                        if (lineItemsByPricebookEntryId.containsKey(oli.PricebookEntryId)){
                            lineItemsByPricebookEntryId.get(oli.PricebookEntryId).add(oli);
                        } else {
                            lineItemsByPricebookEntryId.put(oli.PricebookEntryId, new List<OpportunityLineItem>{oli});
                        }
                    }
                }
            }
            lineItemsByPricebookEntryIdByOppId.put(opp.Id, lineItemsByPricebookEntryId);
        }
        // Process the new and/or updated oli records 
        for (OpportunityLineItem oli : opportunityLineItems){
            Map<Id, List<OpportunityLineItem>> lineItemsByPricebookEntryId = lineItemsByPricebookEntryIdByOppId.get(oli.OpportunityId);
                if (String.isNotBlank(oli.PricebookEntryId)){
                    if (lineItemsByPricebookEntryId.containsKey(oli.PricebookEntryId)){
                        lineItemsByPricebookEntryId.get(oli.PricebookEntryId).add(oli);
                    } else {
                        lineItemsByPricebookEntryId.put(oli.PricebookEntryId, new List<OpportunityLineItem>{oli});
                    }
                }
        }
        return lineItemsByPricebookEntryIdByOppId;       
    }
    /**
     * @description: Private method to retrieve a Collection of Pricebook Entry records 
     */     
    private static Map<Id, PricebookEntry> getPricebookEntries(List<OpportunityLineItem> opportunityLineItems){
        Set<Id> pricebookEntryIds = new Set<Id>();
        for (OpportunityLineItem oli : opportunityLineItems){
            if (String.isNotBlank(oli.PricebookEntryId)){
                pricebookEntryIds.add(oli.PricebookEntryId);
            }
        }
        return new Map<Id, PricebookEntry>([SELECT Id, Product2.Id, Product2.Name
                                            FROM PricebookEntry
                                            WHERE Id IN :pricebookEntryIds]);       
    }       
    /**
     * @description: Extract and process Opportunities belonging to a Collection of record types
     */
    public static Map<Id, Opportunity> getOpportunitiesFromDB(Set<Id> opportunityIds, Set<Id> recordTypeIds) {
        Map<Id, Opportunity> opportuntiesToProcess = new Map<Id, Opportunity>();
        for (Opportunity opp : [SELECT Id, RecordTypeId, Payment_Protocol__c,
                                (SELECT Id, Name, OpportunityId, PricebookEntryId, Payment_Protocol__c
                                FROM OpportunityLineItems)
                                FROM Opportunity
                                WHERE Id IN :opportunityIds
                                AND RecordTypeId IN :recordTypeIds] ){
            opportuntiesToProcess.put(opp.Id, opp);
        }
        return opportuntiesToProcess; 
    }
    /**
     * @description: Validate DoorDash for Business Opportunties for the following
     * BZAP-8947 Prevent DashPass Per Enrollment and Subscription being sold on the same opportunity
     * BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    public static void validateOpportunitiesDoorDashForBusiness(List<OpportunityLineItem> opportunityLineItems) {
        if (RAN_VALIDATION_ONCE) { return; }
        RAN_VALIDATION_ONCE = true;        
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId = getOpportunityLineItemsByOppId(opportunityLineItems);
        Map<Id, Opportunity> opportunitiesToValidate = getOpportunitiesFromDB(opportunityLineItemsByOppId.keySet(), new Set<Id>{doorDashForBusinessRecTypeId});
        if (opportunitiesToValidate.isEmpty()) { return; }
        // Retrieve a Collection of line items with 
        // Top level grouping - Opportunity Id, 2nd level Nested grouping - PricebookEntry Id 
        Map<Id, Map<Id, List<OpportunityLineItem>>> lineItemsByPricebookEntryIdByOppId = getLineItemsByPricebookEntryIdByOppId(opportunitiesToValidate, opportunityLineItems);        
        // Combine all line items to retrieve unique pricebook entry records and others if any
        List<OpportunityLineItem> olisToProcess = new List<OpportunityLineItem>();
        for (Opportunity opp : opportunitiesToValidate.values()){
            olisToProcess.addAll(opp.OpportunityLineItems);
        }
        olisToProcess.addAll(opportunityLineItems);
        // Retrieve unique price book entry records
        Map<Id, PricebookEntry> pricebookEntries = getPricebookEntries(olisToProcess);
        // Perform validation of opportunity line item records
        validateMultiTypeDashPassForWork(opportunityLineItems, lineItemsByPricebookEntryIdByOppId, pricebookEntries);      
        validatePaymentProtocol(opportunitiesToValidate, lineItemsByPricebookEntryIdByOppId);
    }
    /**
     * @description: BZAP-8947 Prevent DashPass Per Enrollment and Subscription being sold on the same opportunity
     */
    public static void validateMultiTypeDashPassForWork(List<OpportunityLineItem> ctx, Map<Id, Map<Id, List<OpportunityLineItem>>> lineItemsByPricebookEntryIdByOppId, Map<Id, PricebookEntry> pricebookEntries) {
        for (Id opportunityId : lineItemsByPricebookEntryIdByOppId.keySet()){
            Map<Id, List<OpportunityLineItem>> lineItemsByPricebookEntryId = lineItemsByPricebookEntryIdByOppId.get(opportunityId);
            List<OpportunityLineItem> oliDashPassPerEnrollments = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliDashPassSubscriptions = new List<OpportunityLineItem>();
            for (Id pricebookEntryId : lineItemsByPricebookEntryId.keySet()){
                String productName = pricebookEntries.get(pricebookEntryId).Product2.Name;
                for (OpportunityLineItem oli : lineItemsByPricebookEntryId.get(pricebookEntryId)){
                    switch on productName {
                        when 'DashPass for Work - Pay Per Enrollment' {
                            oliDashPassPerEnrollments.add(oli);
                        }
                        when 'DashPass for Work - Subscription (Pay Upfront)' {
                            oliDashPassSubscriptions.add(oli);
                        }
                    }
                }           
            }
            if (!oliDashPassPerEnrollments.isEmpty() && !oliDashPassSubscriptions.isEmpty()){
                for (OpportunityLineItem oli : ctx){
                    for (OpportunityLineItem dppOli : oliDashPassPerEnrollments){
                        if (dppOli.OpportunityId.equals(oli.OpportunityId)
                            && dppOli.PricebookEntryId == oli.PricebookEntryId){
                            oli.addError(System.Label.ERROR_MSG_OPP_MULTI_TYPE_DASHPASS_WORK);
                        }
                    }
                    for (OpportunityLineItem dpsOli : oliDashPassSubscriptions){
                        if (dpsOli.OpportunityId.equals(oli.OpportunityId)
                            && dpsOli.PricebookEntryId == oli.PricebookEntryId){
                            oli.addError(System.Label.ERROR_MSG_OPP_MULTI_TYPE_DASHPASS_WORK);
                        }
                    }
                }
            }           
        }
    }
    /**
     * @description: BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    public static void validatePaymentProtocol(Map<Id, Opportunity> opportunitiesToValidate, Map<Id, Map<Id, List<OpportunityLineItem>>> lineItemsByPricebookEntryIdByOppId) {
        for (Id opportunityId : lineItemsByPricebookEntryIdByOppId.keySet()){
            Opportunity opportunity = opportunitiesToValidate.get(opportunityId);
            List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();
            Map<Id, List<OpportunityLineItem>> lineItemsByPricebookEntryId = lineItemsByPricebookEntryIdByOppId.get(opportunityId); 
            for (Id pricebookEntryId : lineItemsByPricebookEntryId.keySet()){
                opportunityLineItems.addAll(lineItemsByPricebookEntryId.get(pricebookEntryId));
            }
            if (String.isNotBlank(opportunity.Payment_Protocol__c) && !opportunityLineItems.isEmpty()){
                Boolean isOppInvoicing = PAYMENT_PROTOCOL_INVOICING.equals(opportunity.Payment_Protocol__c);
                for (OpportunityLineItem oli : opportunityLineItems){
                    if (!isOppInvoicing && PAYMENT_PROTOCOL_INVOICING.equals(oli.Payment_Protocol__c)){
                        oli.Payment_Protocol__c.addError(System.Label.ERROR_MSG_OPP_PAYMENT_PROTOCOL_IS_NOT_INVOICING);
                    }
                }
            }
        }
    }           
}