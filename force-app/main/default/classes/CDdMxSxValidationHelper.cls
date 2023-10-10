/********************************************************************************************************************
* @author Ebby
* @date 11/11/2021
*
* @group Merchant Services
*
* @description Helper class for Opportunity Validations, called from Opportunity Trigger in before context
* 
**************************************************************************************************************************************/

public class CDdMxSxValidationHelper {
    private Map<Id, List<String>> opportunityValidationMessages = new Map<Id, List<String>>() ;
    private CDdMxSxOpportunityHelper opportunityHelper ;
    public static Boolean ranOpportunityValidations = false;
    public class CDdMxSxValidationHelperException extends Exception{}
    /**
     * @description Calls all the Opportunity validations and displays an error message from a list 
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @param Map<Id, Account> Related Accounts on the Opportunity records
     * @return    
    */
    public void runMxSxOpportunityValidations(List<Opportunity> newList, Map<Id, Opportunity> oldMap, Map<Id, Account> accounts){
        if(ranOpportunityValidations){return;}//If the method is run once return as the Opportunityhelper class need not be instantiated 
        //multiple times due to recursion

        Set<Id> opportunityIds = new Set<Id>();
        for(Opportunity newObj :newList){
            if( CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId)){
                opportunityIds.add(newObj.Id);
            }
        }
        if(opportunityIds.isEmpty()){
            return;
        }
        opportunityHelper = new CDdMxSxOpportunityHelper(opportunityIds);
        // Perform opportunity related validations
        if(CDdMxSxConstants.ENABLE_MXSX_DECISIONMAKER_VALIDATION){
            verifyImplementationCallEventforClosedWon(newList, oldMap);
        }
        verifyStorefrontOpportunityQualifyingQuestionsforClosedWon(newList, oldMap);
        //Add All the error Messages here to the Opportunity
        for(Opportunity newObj :newList){
            if(opportunityValidationMessages.containsKey(newObj.Id)){
               newObj.addError(String.join(opportunityValidationMessages.get(newObj.Id), ','));
            }
        }
        ranOpportunityValidations = true;
    }
    /**
     * @description Verifies if there is an Implementation call Event created for an opportunity before moving to closed-won
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @return    
    */
    private void verifyImplementationCallEventforClosedWon(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldMap){
        Map<String, Set<String>> opportunityDecisionMaker = new Map<String, Set<String>>();
        for(Opportunity newObj: newOpportunities){
            Opportunity oldObj = (oldMap != null) ? oldMap.get(newObj.Id) : null;
            if( CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId) 
                && CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newObj.StageName) 
                && CDdMxSxTriggerHelper.hasFieldValueChanged(newObj, oldObj, 'StageName') 
                && opportunityHelper.hasNetNewStorefrontPricing(newObj.Id)
                && !opportunityHelper.isSelfServe(newObj.Id)){
                    if(newObj.Decision_Maker__c == null){
                        populateErrorList(newObj.Id, System.Label.MxSx_StoreFront_Opportunity_Decision_Maker_Error);
                    }else{
                        if(opportunityDecisionMaker.containsKey(newObj.Decision_Maker__c)){
                            opportunityDecisionMaker.get(newObj.Decision_Maker__c).add(newObj.Id);
                        }else{
                            opportunityDecisionMaker.put(newObj.Decision_Maker__c, new Set<String>{newObj.Id});
                        }
                    }
            }
        }
        if(opportunityDecisionMaker.isEmpty()){ return; }
        Map<Id, Event> opportunityStorefrontEvents = getopportunityStorefrontEvents(opportunityDecisionMaker.keySet()); 
        
        for(Opportunity newObj: newOpportunities){
            if( opportunityDecisionMaker.containsKey(newObj.Decision_Maker__c) && opportunityDecisionMaker.get(newObj.Decision_Maker__c).contains(newObj.Id)){
                if(opportunityStorefrontEvents == null || !opportunityStorefrontEvents.containsKey(newObj.Decision_Maker__c)){
                    populateErrorList(newObj.Id, System.Label.MxSx_StoreFront_Opportunity_No_Storefront_Event_Error);
                }
            }
        } 
    }
    /**
     * @description BZAP-12366 - Validate for Storefront (net-new pricing) Opportunities, whether the Qualification Questions are completed
     * @param List<Opportunity> Trigger.new a list of new Opportunity records
     * @param Map<Id, Opportunity> Trigger.oldMap a Map of old Opportunity records
     * @return    
    */
    private void verifyStorefrontOpportunityQualifyingQuestionsforClosedWon(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldMap){
        for(Opportunity newObj: newOpportunities){
            Opportunity oldObj = (oldMap != null) ? oldMap.get(newObj.Id) : null;
            if( CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newObj.RecordTypeId) 
                && CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(newObj.StageName) 
                && CDdMxSxTriggerHelper.hasFieldValueChanged(newObj, oldObj, 'StageName') 
                && opportunityHelper.hasNetNewStorefrontPricing(newObj.Id)
                && !opportunityHelper.isSelfServe(newObj.Id)
                && !opportunityHelper.isCurrentUserSelfServe()){
                if(!newObj.Storefront_Qualification_Complete__c){
                    populateErrorList(newObj.Id, System.Label.MxSx_StoreFront_Opportunity_Qualifying_Questions_Check_Error);
                }
            }
        }
    }    
    /**
     * @description Populates the class attribute opportunityValidationMessages with the message being passed
     * @param String Opportunity Id 
     * @param String Error message corresponding to the Opportunity
     * @return    
    */
    private void populateErrorList(String oppId, String message){
        if(opportunityValidationMessages.containsKey(oppId)){
            opportunityValidationMessages.get(oppId).add(message);
        }else {
            opportunityValidationMessages.put(oppId, new List<String>{message});
        }
    }
    /**
     * @description Gets the List of Implementation call Events associated with DM of the Opportunity
     * @param Set<String> Set of related Contact Ids associated as DM's for MxSx Opportunities
     * @return Map<Id, Event>, collection of Contacts and associated Implementation call Events   
    */
    private Map<Id, Event> getopportunityStorefrontEvents(Set<String> opportunityDecisionMaker){
        Map<Id, Event> opportunityStorefrontEvents = new  Map<Id, Event>();
        for(Event e: [Select Id, Type, WhoId from Event where WhoId In : opportunityDecisionMaker AND 
                        Subject = :CDdMxSxConstants.STOREFRONT_EVENTNAME ]){
                if(e.WhoId != null && !opportunityStorefrontEvents.containsKey(e.WhoId)){
                    opportunityStorefrontEvents.put(e.WhoId, e);
                }
        } 
        return opportunityStorefrontEvents ;
    }

}