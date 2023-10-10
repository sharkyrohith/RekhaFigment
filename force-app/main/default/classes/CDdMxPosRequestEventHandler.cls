/**
    @author: Dan Thoreson
    @date: 20-Jan-2023
    @group: Mx Services
    @description: Helper class for handling MxSx Events related to POS Integration Requests.
    @test class: CDdMxPosRequestEventHandlerTest
**/
public class CDdMxPosRequestEventHandler {

    public static Id posIntegrationsCaseQueueId { get {
        if(posIntegrationsCaseQueueId == null) {
            // This opimtization helper will simply return null if you try to get a Queue Id from the map and the setQueueMap() method
            // has not yet been called, rather than calling it and initializing it one time. Unfortunately, then the calling code has to do this.
            if(CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION) == null) {
                CDdGenericTriggerOptimizationHelper.setQueueMap(new List<String>{ CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION }, new Set<Id>());
            }

            posIntegrationsCaseQueueId = CDdGenericTriggerOptimizationHelper.getQueueIdByDevName(CDdCaseTriggerHelperV2.QUEUE_POS_INTEGRATION);
        }

        return posIntegrationsCaseQueueId;
    } set; }

    private static fflib_ISObjectUnitOfWork uow { get {
        if(uow == null) {
            uow = Application.UnitOfWork.newInstance();
        }

        return uow;
    } set; }

    /**
        @author: Dan Thoreson
        @date: 19-Jan-2023
        @description: Takes MxSx_Event__e records for POS Requests and converts
                      them to Apex wrapper objects.
    **/
    public static void unpackPosRequestEvents(List<MxSx_Event__e> mxSxEvents) {
        List<CDdMxSxPOSRequestWrappers.POSRequest> posRequests = new List<CDdMxSxPOSRequestWrappers.POSRequest>();

        for(MxSx_Event__e thisEvent : mxSxEvents) {
            if(String.isBlank(thisEvent.Payload__c) || thisEvent.Payload__c == '{}') {
                continue;
            }

            CDdMxSxPOSRequestWrappers.POSRequest posObj = (CDdMxSxPOSRequestWrappers.POSRequest) JSON.deserialize(thisEvent.Payload__c, CDdMxSxPOSRequestWrappers.POSRequest.class);
            posRequests.add(posObj);
        }

        if(!posRequests.isEmpty()) {
            CDdMxSxPOSRequestWrappers.setMarketplaceOpportunityIdsForCaseRetrieval(CDdMxPosRequestEventHandler.getOpportunityIdsFromRequests(posRequests));
            CDdMxPosRequestEventHandler.createPosIntegrationCases(posRequests);
            CDdMxPosRequestEventHandler.updateOpportunityCreatedFlags(posRequests);
            uow.commitWork();
        }
    }

    /**
        @author: Dan Thoreson
        @date: 20-Jan-2023
        @description: From an inputted list of POSRequest objects, generate POS Integrations Request Cases.
                      Uses fflib Unit of Work patterns for DML.
    **/
    public static void createPosIntegrationCases(List<CDdMxSxPOSRequestWrappers.POSRequest> posRequests) {
        for(CDdMxSxPOSRequestWrappers.POSRequest thisRequest : posRequests) {
            Case thisPosCase = initPosIntegrationCase(thisRequest);
            uow.registerNew(thisPosCase);
        }
    }

    /**
        @author: Dan Thoreson
        @date: 07-Feb-2023
        @description: Updates the Activation_Case_Created__c boolean flag on Opportunities to indicate that a POS
                      Case has been created.
    **/
    public static void updateOpportunityCreatedFlags(List<CDdMxSxPOSRequestWrappers.POSRequest> posRequests) {
        Set<Id> opportunityIds = new Set<Id>();

        for(CDdMxSxPOSRequestWrappers.POSRequest thisRequest : posRequests) {
            if(thisRequest.sourceOpportunity != null) {
                opportunityIds.add(thisRequest.sourceOpportunity.Id);
            }
        }

        List<Opportunity> opportunities = OpportunitiesSelector.newInstance().selectByIdExtraFields(opportunityIds, new Set<String> { 'Activation_Case_Created__c' });

        for(Opportunity thisOpp : opportunities) {
            if(!thisOpp.Activation_Case_Created__c) {
                thisOpp.Activation_Case_Created__c = true;
                uow.registerDirty(thisOpp);
            }
        }
    }

    /**
        @author: Dan Thoreson
        @date: 24-Jan-2023
        @description: Filters a list of CDdMxSxPOSRequestWrappers.POSRequest objects to the source Opportunity IDs
    **/
    public static Set<Id> getOpportunityIdsFromRequests(List<CDdMxSxPOSRequestWrappers.POSRequest> requests) {
        Set<Id> opportunityIds = new Set<Id>();

        for(CDdMxSxPOSRequestWrappers.POSRequest thisRequest : requests) {
            opportunityIds.add(thisRequest.sourceOpportunity.Id);
        }

        return opportunityIds;
    }

    /**
        @author: Dan Thoreson
        @date: 20-Jan-2023
        @description: Initialize a POS Integration Case and its field values.
    **/
    public static Case initPosIntegrationCase(CDdMxSxPOSRequestWrappers.POSRequest posObj) {
        Case thisCase = CDdOpportunityCaseHelper.createPostSaleCase(posObj.sourceOpportunity, null);
        thisCase.RecordTypeId = CDdSchemaUtils.CASE_RT.posIntegrationsId();
        thisCase.ParentId = posObj.marketplaceOnboardingCase?.Id;
        thisCase.Opportunity_Name__c = posObj.sourceOpportunity.Id;
        thisCase.AccountId = posObj.sourceOpportunity.AccountId;
        thisCase.Priority = 'Normal';
        thisCase.Subject = String.format('Net New Store {0} {1}', new List<Object>{ posObj.accountName, posObj.marketplaceOnboardingCase?.CaseNumber });
        thisCase.POS_Integration_Type__c = posObj.sourceOpportunity.POS_Integration_Type__c;
        thisCase.POS_Integration_ID__c = posObj.sourceOpportunity.POS_Integration_ID__c;
        thisCase.POS_Fallback_Protocol__c = posObj.sourceOpportunity.POS_Fallback_Protocol__c;
        thisCase.Due_Date__c = posObj.sourceOpportunity.Proposed_Date_of_Activation__c;
        thisCase.Go_Live_Date__c = posObj.sourceOpportunity.Proposed_Date_of_Activation__c;
        thisCase.OwnerId = CDdMxSxOpportunityHelper.isSelfServe(posObj.sourceOpportunity) && ('square'.equalsIgnoreCase(posObj.sourceOpportunity.POS_Integration_Type__c) || 'toast'.equalsIgnoreCase(posObj.sourceOpportunity.POS_Integration_Type__c))?
        CDdGenericTriggerOptimizationHelper.getQueueIdByDevName('Onboarding_SSMO_Square_POS'): CDdMxPosRequestEventHandler.posIntegrationsCaseQueueId;
        thisCase.Origin = CDdMxSxOpportunityHelper.isSelfServe(posObj.sourceOpportunity)? CDdMxSxConstants.SELF_SERVE_CASE_ORIGIN : CDdSupportConstants.ORIGIN_PROTOCOL_CHANGE;
        return thisCase;
    }
}