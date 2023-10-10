/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 10/29/2020
*
*
* @group Opportunity Validation
*
* @description Helper class to perform validation on Opportunity and related Opportunity Products
**********************************************************************************************************************/
public class CDdOpportunityValidationHelper {
    public static Boolean RAN_VALIDATION_ONCE = false;
    public static Boolean RAN_CLOSED_WON_VALIDATION_ONCE = false;
	public static Id doorDashForBusinessRecTypeId = CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId();
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();
	public static final String PAYMENT_PROTOCOL_INVOICING = 'Invoicing';
    public static final String OPPORTUNITY_DOORDASH_DRIVE_RT = 'Opportunity_DoorDash_Drive';
    public static final String OPPORTUNITY_CLOSED_DRIVE_FIELD_SET = 'Closed_Drive_Opportunity_Fields';

    /**
     * @description: Extract and process Opportunities belonging to a Collection of record types
     */
    public static Map<Id, Opportunity> getOpportunities(List<Opportunity> opportunities, Set<Id> recordTypeIds) {
        Map<Id, Opportunity> opportuntiesToProcess = new Map<Id, Opportunity>();
        for (Opportunity opp : opportunities){
            if (recordTypeIds.contains(opp.RecordTypeId)) {
                opportuntiesToProcess.put(opp.Id, opp);
            }
        }
        return opportuntiesToProcess;
    }
    private static Map<Id, List<OpportunityLineItem>> getOpportunityLineItemsByOppId(Set<Id> opportunityIds, Set<Id> recordTypeIds){
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId = new Map<Id, List<OpportunityLineItem>>();
        for (Opportunity opp : [SELECT Id, RecordTypeId, Payment_Protocol__c,
                                (SELECT Id, Name, OpportunityId, PricebookEntryId,
                                PricebookEntry.Product2.Name, Payment_Protocol__c
                                FROM OpportunityLineItems)
                                FROM Opportunity
                                WHERE Id IN :opportunityIds
                                AND RecordTypeId IN :recordTypeIds] ){
            opportunityLineItemsByOppId.put(opp.Id, opp.OpportunityLineItems);
        }
        return opportunityLineItemsByOppId;
    }
    /**
     * @description: Validate 'DoorDash for Business' Opportunities for the following
     * BZAP-8947 Prevent DashPass Per Enrollment and Subscription being sold on the same opportunity
     * BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    public static void validateOpportunitiesDoorDashForBusiness(List<Opportunity> opportunities) {
        if (RAN_VALIDATION_ONCE) { return; }
        RAN_VALIDATION_ONCE = true;
        Map<Id, Opportunity> opportunitiesToValidate = getOpportunities(opportunities, new Set<Id>{doorDashForBusinessRecTypeId});
        if (opportunitiesToValidate.isEmpty()) { return; }
        Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId = getOpportunityLineItemsByOppId(opportunitiesToValidate.keySet(), new Set<Id>{doorDashForBusinessRecTypeId});
        validateMultiTypeDashPassForWork(opportunitiesToValidate, opportunityLineItemsByOppId);
        validatePaymentProtocol(opportunitiesToValidate, opportunityLineItemsByOppId);
    }
    /**
     * @description: BZAP-8947 Prevent DashPass Per Enrollment and Subscription being sold on the same opportunity
     */
    public static void validateMultiTypeDashPassForWork(Map<Id, Opportunity> opportunities, Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId) {
        if (opportunityLineItemsByOppId.isEmpty()) return;
        for (Id opportunityId : opportunities.keySet()){
            Boolean hasDashPassForWorkEnrollment = false;
            Boolean hasDashPassForWorkSubscription = false;
            List<OpportunityLineItem> opportunityLineItems = opportunityLineItemsByOppId.get(opportunityId);
            for (OpportunityLineItem oli : opportunityLineItems){
                switch on oli.PricebookEntry.Product2.Name {
                    when 'DashPass for Work - Pay Per Enrollment' {
                        hasDashPassForWorkEnrollment = true;
                    }
                    when 'DashPass for Work - Subscription (Pay Upfront)' {
                        hasDashPassForWorkSubscription = true;
                    }
                }
            }
            if (hasDashPassForWorkEnrollment && hasDashPassForWorkSubscription){
                opportunities.get(opportunityId).addError(System.Label.ERROR_MSG_OPP_MULTI_TYPE_DASHPASS_WORK);
            }
        }
    }
    /**
     * @description: BZAP-8948 Ensure alignment of payment protocol for rec type - DoorDash for Business
     */
    public static void validatePaymentProtocol(Map<Id, Opportunity> opportunities, Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOppId) {
        if (opportunityLineItemsByOppId.isEmpty()) return;
        for (Id opportunityId : opportunities.keySet()){
            Opportunity opportunity = opportunities.get(opportunityId);
            List<OpportunityLineItem> opportunityLineItems = opportunityLineItemsByOppId.get(opportunityId);
            if (String.isNotBlank(opportunity.Payment_Protocol__c) && !opportunityLineItems.isEmpty()){
                Boolean isOppInvoicing = PAYMENT_PROTOCOL_INVOICING.equals(opportunity.Payment_Protocol__c);
                for (OpportunityLineItem oli : opportunityLineItems){
                    if (!isOppInvoicing && PAYMENT_PROTOCOL_INVOICING.equals(oli.Payment_Protocol__c)){
                        opportunity.Payment_Protocol__c.addError(System.Label.ERROR_MSG_OPP_PAYMENT_PROTOCOL_IS_NOT_INVOICING);
                    }
                }
            }
        }
    }

    /**
     * @description: BASD-31399 Tweak to Drive C/W Opportunity Lock Rule
     * Method to throw an error when Closed opportunity is updated with non excluded fieldSet fields are mofieied
     */
    public static void validateClosedDriveOpportunities(List<Opportunity> newList, Map<Id,Opportunity> oldMap) {
        if (RAN_CLOSED_WON_VALIDATION_ONCE) { return; }
        RAN_CLOSED_WON_VALIDATION_ONCE = true;
        // will be skipped for Validation bypass and Drive CW override users.
        if(Validation_Bypass__c.getInstance().Bypass_Opportunity_Validations__c == True
                || Drive_CW_Override__c.getInstance().Override_Drive_CW__c == True){

            return ;
        }

        List<Opportunity> processOpportunities = new List<Opportunity>();
        for(Opportunity opp:newList){
            if(
                (
                    opp.RecordTypeId == Record_Type_Values__mdt.getInstance(OPPORTUNITY_DOORDASH_DRIVE_RT).Record_Type_Id_18__c
                    || oldMap.get(opp.Id).RecordTypeId == Record_Type_Values__mdt.getInstance(OPPORTUNITY_DOORDASH_DRIVE_RT).Record_Type_Id_18__c
                )
            ){
                if(oldMap.get(opp.Id).StageName == 'Closed Won'){
                    //If Old stage is Closed Won and Stagename is modified, then throw an error

                    if(opp.StageName != oldMap.get(opp.Id).StageName){
                        opp.addError(Label.Closed_Drive_Opportunity_Stage_Validation_Message);
                        return ;
                    }else{
                        processOpportunities.add(opp);
                        // If not stage is modified and Closed Won opportunity, then check for other fields are modified or not
                    }

                }

            }
        }

        if(processOpportunities.isEmpty()){
            return ;
        }
        //Getting excluded fields from Field set.
        List<Schema.FieldSetMember> fieldSetMemberList =  SOBJECT_TYPES.get('Opportunity').
                                                                getDescribe().FieldSets.getMap().
                                                                get(OPPORTUNITY_CLOSED_DRIVE_FIELD_SET).getFields();
        Set<string> excludeFieldSet = new Set<string>();
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
            excludeFieldSet.add(fieldSetMemberObj.getFieldPath());
        }
        //Getting all updatable fields which are not in Excluded fields.
        Set<string> fieldAPINames = new Set<string>();
        for(Schema.SObjectField sObjField : SOBJECT_TYPES.get('Opportunity').
                                                               getDescribe().fields.getMap().Values()){

            if(sObjField.getDescribe().isUpdateable() && !excludeFieldSet.contains(sObjField.getDescribe().getName())){
                fieldAPINames.add(sObjField.getDescribe().getName());
            }
        }

        for(Opportunity opp:processOpportunities){
            //Checking if Other fields are modified, then throw an error.
            boolean isOtherFieldModified = false;
            for(String fieldAPI:fieldAPINames){
                if(opp.get(fieldAPI) != oldMap.get(opp.Id).get(fieldAPI)){
                    isOtherFieldModified = True;
                    break;
                }
            }

            if(isOtherFieldModified == True){
                opp.addError(Label.Closed_Drive_Opportunity_Validation_Message);
                return ;
            }
        }
    }

    /**
        @author: Dan Thoreson
        @date: 04-Jan-2023
        @description: Verifies the Product Detail (Product_Detail__c) for Storefront are completed before an Opportunity
                      proceeds to relevant phases:
                        - Sales Opportunities: Stage changes to Closed - Won
                        - SSMO Opportunities: OwnerId is updated
    **/
    public static void validateCompletionOfStorefrontInfo(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        // Do not proceed if the user or profile has turned off Opportunity validations
        if(CDdOpportunityTriggerHelper.skipValidation('Bypass_Opportunity_Validations__c')) {
            return;
        }

        Set<Id> opportunityIdsToCheck = new Set<Id>();

        for(Opportunity newOpportunity : newList) {
            Opportunity oldOpportunity = (oldMap != null && oldMap.containsKey(newOpportunity.Id)) ? oldMap.get(newOpportunity.Id) : new Opportunity();

            Boolean isSsmo = CDdMxSxOpportunityHelper.isSelfServe(newOpportunity);
            Boolean isSales = !isSsmo;

            if(!CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS.contains(newOpportunity.RecordTypeId)) {
                continue;
            }

            Boolean stageChanged = newOpportunity.StageName != oldOpportunity.StageName;
            Boolean isClosedWon = newOpportunity.StageName == CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON;

            // Implicitly checks for change to OwnerId as well, since the only way the new owner would not be self-serve and the previous owner would be is if the owner changed.
            Boolean changedFromSelfServeUser = !CDdMxSxOpportunityHelper.isUserSelfServe(newOpportunity.OwnerId) && CDdMxSxOpportunityHelper.isUserSelfServe(oldOpportunity.OwnerId);

            // Verify Sales Opportunities when they are Closed Won, and verify SSMO Opportunities when the Owner changes to a Sales user
            if((isSales && stageChanged && isClosedWon) || (isSsmo && changedFromSelfServeUser)) {
                opportunityIdsToCheck.add(newOpportunity.Id);
            }
        }

        // First check if any Opportunities were changed in the manner we're concerned with, and exit the method if we
        // don't have any. This prevents us from having to do unnecessary queries for Product Details and Order Items
        // since the Opportunity might not even be in a state where we'd want to validate it.
        if(opportunityIdsToCheck.isEmpty()) {
            return;
        }

        // Determine if we have any Storefront Opportunities -- i.e., Opportunities with a Storefront Package OrderItem -- to consider.
        Set<Id> oppsWithStorefrontProduct = CDdMxSxOpportunityHelper.getStorefrontOpportunities(opportunityIdsToCheck);

        if(oppsWithStorefrontProduct.isEmpty()) {
            return;
        }

        // Lastly, get the Product Details for the relevant Opportunities and proceed with our verification.
        Map<Id, Opportunity> oppsWithProductDetails = new Map<Id, Opportunity>(OpportunitiesSelector.newInstance().selectOpportunitiesWithProductDetails(oppsWithStorefrontProduct));

        for(Opportunity thisOpportunity : newList) {
            if(!oppsWithProductDetails.containsKey(thisOpportunity.Id)) {
                continue;
            }

            // Make sure there is a Product_Detail__c record attached to each Opportunity that has a Storefront Product on it.
            // We are not validating the attributes of the Product_Detail__c record, just verifying that it exists.
            if(oppsWithStorefrontProduct.contains(thisOpportunity.Id) && oppsWithProductDetails.get(thisOpportunity.Id).Product_Details__r.isEmpty()) {
                thisOpportunity.addError(System.Label.ERROR_MSG_MISSING_STOREFRONT_DETAILS);
            }
        }
    }
}