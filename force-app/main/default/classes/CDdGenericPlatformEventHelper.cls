/**
 * @author Knick
 * @date 7/2020
 * @description Generic Platform Event creation, publishing and handling
 *              Add to PlatformEventType, plaformEventMap as needed, add call in handler
 *
**/
public class CDdGenericPlatformEventHelper {
    /**
    * @author Knick
    * @description Extend the Exception class for usage by this class
    **/
    public class CDdGenericPlatformEventException extends Exception {}
    /**
    * @author Knick
    * @description Define the Platform Event Types used by the system
    **/
    public enum PlatformEventType {
        ACCOUNT_ROLLUP,                    // Used by CDdLeadTriggerHandler ...
        ACCOUNT_LEAD_ROLLUP,                    // Used by CDdLeadTriggerHandler ...
        LEAD_VERIFY_EMAIL,                      // Used by CDdLeadTriggerHandler ...
        CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT,   // Used by CDdCaseTriggerHelper ...
        CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE,    // Used by CDdCaseTriggerHelper ...
        CHECK_ACCOUNT_COVERAGE,                  // Used by CDdAccountHelperMethod ...
        COPY_CUSTOMER_DETAIL_TO_ACCOUNT,        // Used by CDdSObjectFieldCopyController ...
        COPY_STORE_DETAIL_TO_ACCOUNT,           // Used by CDdSObjectFieldCopyController ...
        DELIVER_TABLET_MILESTONE,
        SETUP_MENU_MILESTONE,
        TEST_EVENT,
        LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD,        // Used by the CDdGenericPlatformEventHelperTest class ...
        INCREMENT_VENDORCHATCOUNT,               //used to increment vendor chat count
        OPP_BIZ_VERIFICATION_DOC_ATTACHED,      // Used by CDdOpportunityTriggerHelper
        DISPATCH_LEAD_UPSERT,                   // Used by CDdDispatchRecordService
        ACCOUNT_REPARENT,                       // Used by CDdOpportunityTriggerHelper
        ACCOUNT_ULTIMATE_PARENT,                //Used by CDdAccountHelperMethod
        PHOTOSHOOT_CASE,                         // Used by CDdOpportunityCaseHelper
        CASE_DETAIL_CREATION,                     // Used by CDdCaseTriggerHelper
        PROACTIVE_CASE_CREATION,                 //Used by CDdCaseTriggerHelperV2
        PROACTIVE_CASE_INFO_RECORD_CREATION,     //Used by CDdCaseTriggerHelperV2
        CREATE_CASE_FEED                         //Can be used to create Case Feed
    }
    public static final Map<PlatformEventType, String> platformEventMap = new Map<PlatformEventType, String> {
        PlatformEventType.ACCOUNT_ROLLUP        =>  'Account Rollup',
        PlatformEventType.ACCOUNT_LEAD_ROLLUP   =>  'Account Lead Rollup',
        PlatformEventType.LEAD_VERIFY_EMAIL   =>  'Lead Verify Email',
        PlatformEventType.CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT  =>  'Case Send Email POS Support Redirect',
        PlatformEventType.CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE  =>  'Case Send Email POS Post Activation Marketplace',
        PlatformEventType.CHECK_ACCOUNT_COVERAGE => 'Check Account Coverage',
        PlatformEventType.COPY_CUSTOMER_DETAIL_TO_ACCOUNT   =>  'Copy Customer Detail to Account',
        PlatformEventType.COPY_STORE_DETAIL_TO_ACCOUNT  =>  'Copy Store Detail to Account',
        PlatformEventType.DELIVER_TABLET_MILESTONE => 'Change Deliver Tablet Milestone status',
        PlatformEventType.SETUP_MENU_MILESTONE => 'Change Setup Menu Milestone status',
        PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD  =>  'LCT TrueUp Vendor Dist',
        PlatformEventType.TEST_EVENT            =>  'TEST EVENT',
        PlatformEventType.INCREMENT_VENDORCHATCOUNT  =>  'LCT Increment VendorCC',
        PlatformEventType.OPP_BIZ_VERIFICATION_DOC_ATTACHED  =>  'Business Verification Document Attached',
        PlatformEventType.ACCOUNT_REPARENT   =>  'Account Reparent',
        PlatformEventType.ACCOUNT_ULTIMATE_PARENT  =>  'Account Ultimate Parent',
        PlatformEventType.PHOTOSHOOT_CASE => 'Photoshoot Case',
        PlatformEventType.CASE_DETAIL_CREATION => 'Case Detail Creation',
        PlatformEventType.DISPATCH_LEAD_UPSERT => 'Dispatch Lead Upsert',
        PlatformEventType.PROACTIVE_CASE_CREATION => 'Proactive Case Creation',
        PlatformEventType.PROACTIVE_CASE_INFO_RECORD_CREATION => 'Proactive Case Info object Record Creation',
        PlatformEventType.CREATE_CASE_FEED => 'Create Case Feed'
    };

    private static Map<String,PlatformEventType> eventNameToEnumMap = null;
    public static Map<String,PlatformEventType> getEventNameToEnumMap() {
        if (eventNameToEnumMap != null) {
            return eventNameToEnumMap;
        }
        eventNameToEnumMap = new Map<String,PlatformEventType>();
        for (PlatformEventType pType : platformEventMap.keySet()) {
            eventNameToEnumMap.put(platformEventMap.get(pType),pType);
        }
        return eventNameToEnumMap;
    }

    public static String strEventType(PlatformEventType eType) {
        String eventString = platformEventMap.get(eType);
        if (eventString != null) return eventString;
        throw new CDdGenericPlatformEventException('Platform Event Type: ' + eType + ' not found in platformEventMap.');
    }

    public static PlatformEventType typeOf(String strEventType) {
        PlatformEventType eType = getEventNameToEnumMap().get(strEventType);
        if (eType != null) {
            return eType;
        }
        throw new CDdGenericPlatformEventException('Platform Event Type not found in platformEventMap for: ' + strEventType + '.');
    }
    /**
    * @author Knick
    * @description Create Platform Events from a Set<Id>
    **/
    public static List<Generic_Platform_Event__e> createEvents(PlatformEventType eType, Set<Id> sobjIds, String payload) {
        String eventString = strEventType(eType);
        List<Generic_Platform_Event__e> eventList = new List<Generic_Platform_Event__e>();
        if(sobjIds == null || sobjIds.isEmpty()) {
            eventList.add(new Generic_Platform_Event__e(
                sObjectId__c = null,
                Event_Type__c = eventString,
                Payload__c = payload
            ));
        } else {
            for (Id sobjId : sobjIds) {
                eventList.add(new Generic_Platform_Event__e(
                    sObjectId__c = sobjId,
                    Event_Type__c = eventString,
                    Payload__c = payload
                ));
            }
        }
        return eventList;
    }
    /**
    * @author Knick
    * @description Create Platform Events from a List<Id>
    **/
    public static List<Generic_Platform_Event__e> createEvents(PlatformEventType eType, List<Id> sobjIds) {
        return createEvents(eType, new Set<Id>(sobjIds), (String)null);
    }
    /**
    * @author Knick
    * @description Publish Platform Events
    **/
    public static void publishEvents(List<Generic_Platform_Event__e> eventList) {
        EventBus.publish(eventList);
    }
    /**
    * @author Knick
    * @description Create and Publish Platform Events from a Set<Id>
    **/
    public static void publishEvents(PlatformEventType eType, Set<Id> sobjIds) {
        publishEvents(createEvents(eType, sobjIds,(String)null));
    }
    /**
    * @author Knick
    * @description Create and Publish Platform Events from a List<Id>
    **/
    public static void publishEvents(PlatformEventType eType, List<Id> sobjIds) {
        publishEvents(eType, new Set<Id>(sobjIds),(String)null);
    }
    /**
    * @author Sahil
    * @description Create and Publish Platform Events from a Payload
    **/
    public static void publishEvents(PlatformEventType eType, Set<Id> sobjIds, String payload) {
        publishEvents(createEvents(eType,sobjIds,payload));
    }

    /**
    * @author Knick
    * @description Handle Custom Platform Events
    *
    *               Raju L - Winter 22 release provides us enum.valueOf to convert a string to enum.
    *               Using this and adding to map / using map is O(n) -
    *                       where n is the size of eventList array (cpu for iterating thru 1000 eventList = 19)
    *               The previous logic of iterating thru the entire eventList in inner for loops is very expensive O(n * m) -
    *                       where n is the size of eventList array and m is the size of the enum (cpu for iterating thru 1000 eventList = 150)
    **/
    public static void handleEvents(List<Generic_Platform_Event__e> eventList) {
        Boolean runOldLogic = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_Upgraded_Generic_Platform_Event__c');

        if (runOldLogic) {
            handleEvents_Old(eventList);
            return;
        }

        Map<PlatformEventType,List<Generic_Platform_Event__e>> eventMap = new Map<PlatformEventType,List<Generic_Platform_Event__e>>();

        for (Generic_Platform_Event__e e : eventList) {
            PlatformEventType eType = typeOf(e.Event_Type__c);
            if (!eventMap.containsKey(eType)) {
                eventMap.put(eType, new List<Generic_Platform_Event__e>());
            }
            eventMap.get(eType).add(e);
        }

        for (PlatformEventType eType : eventMap.keySet()) {
            List<Generic_Platform_Event__e> typeEvents = eventMap.get(eType);
            switch on eType {
                when ACCOUNT_ROLLUP {
                    CDdAccountHelperMethods.handleAccountRollupEvents(typeEvents);
                }
                when ACCOUNT_LEAD_ROLLUP {
                    CDdLeadTriggerHelper.handleRollupEvents(typeEvents);
                }
                when LEAD_VERIFY_EMAIL {
                    CDdLeadTriggerHelper.handleVerifyEmailEvents(typeEvents);
                }
                when CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT {
                    CDdCaseEventHelper.handleSendEmailEvents(eType, typeEvents);
                }
                when CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE {
                    CDdCaseEventHelper.handleSendEmailEvents(eType, typeEvents);
                }
                when SETUP_MENU_MILESTONE {
                    CDdOpportunityTriggerHelper.handleSetupMenuMilestones(typeEvents);
                }
                when LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD {
                    CDdLiveChatTransEventTriggerHandler.trueUpVendorDistributions(typeEvents[0].sObjectId__c);
                }
                when INCREMENT_VENDORCHATCOUNT {
                    CDdLiveChatTransTriggerHandlerV2.handleIncrementVendorCCPE(typeEvents);
                }
                when CHECK_ACCOUNT_COVERAGE {
                    CDdAccountHelperMethods.handleCheckAccountCoverage(typeEvents);
                }
                when OPP_BIZ_VERIFICATION_DOC_ATTACHED {
                    CDdMerchantDocumentHelper.handleOpportunityUpdatesForBusinessVerificationDocument(typeEvents);
                }
                when DISPATCH_LEAD_UPSERT {
                    CDdDispatchRecordService.upsertLeads(typeEvents);
                }
                when ACCOUNT_REPARENT {
                    CDdAccountHelperMethods.handleAccountReparent(typeEvents);
                }
                when ACCOUNT_ULTIMATE_PARENT {
                    CDdAccountHelperMethods.processUltimateParentEvents(typeEvents);
                }
                when PHOTOSHOOT_CASE {
                    CDdOpportunityCaseHelper.handleAsyncPhotoshootCase(typeEvents);
                }
                when CASE_DETAIL_CREATION {
                    CDdCaseEventHelper.handleCaseDetailCreationEvent(typeEvents);
                }
                when PROACTIVE_CASE_CREATION {
                    CDdCaseEventHelper.handleProactiveCaseRecordCreation(typeEvents);
                }
                when PROACTIVE_CASE_INFO_RECORD_CREATION {
                    CDdCaseEventHelper.handleProactiveCaseInfoRecordCreation(typeEvents);
                }
                when CREATE_CASE_FEED {
                    CDdCaseEventHelper.createCaseFeedItem(typeEvents);
                }
                when TEST_EVENT {
                    // Do nothing for the test. Remember to keep this as the last when for test class coverage.
                }
            }
        }
    }

    public static void handleEvents_Old(List<Generic_Platform_Event__e> eventList) {
        for (PlatformEventType eType : platformEventMap.keySet()) {
            String strEvent = strEventType(eType);
            List<Generic_Platform_Event__e> typeEvents = new List<Generic_Platform_Event__e>();

            for (Generic_Platform_Event__e event : eventList) {
                if (event.Event_Type__c == strEvent) {
                    typeEvents.add(event);
                }
            }

            if (typeEvents.size() > 0) {
                if (eType == PlatformEventType.ACCOUNT_ROLLUP) {
                    CDdAccountHelperMethods.handleAccountRollupEvents(typeEvents);
                }
                else if (eType == PlatformEventType.ACCOUNT_LEAD_ROLLUP) {
                    CDdLeadTriggerHelper.handleRollupEvents(typeEvents);
                }
                else if (eType == PlatformEventType.LEAD_VERIFY_EMAIL) {
                    CDdLeadTriggerHelper.handleVerifyEmailEvents(typeEvents);
                }
                else if (eType == PlatformEventType.CASE_SEND_EMAIL_POS_SUPPORT_REDIRECT) {
                    CDdCaseEventHelper.handleSendEmailEvents(eType, typeEvents);
                }
                else if (eType == PlatformEventType.CASE_SEND_EMAIL_POS_POST_ACTIVATION_MARKETPLACE) {
                    CDdCaseEventHelper.handleSendEmailEvents(eType, typeEvents);
                }
                else if (eType == PlatformEventType.SETUP_MENU_MILESTONE) {
                    CDdOpportunityTriggerHelper.handleSetupMenuMilestones(typeEvents);
                }
                else if (eType == PlatformEventType.LIVE_CHAT_TRANSCRIPT_TRUE_UP_VD) {
                    CDdLiveChatTransEventTriggerHandler.trueUpVendorDistributions(typeEvents[0].sObjectId__c);
                }
                else if (eType == PlatformEventType.INCREMENT_VENDORCHATCOUNT) {
                    CDdLiveChatTransTriggerHandlerV2.handleIncrementVendorCCPE(typeEvents);
                }
                else if (eType == PlatformEventType.CHECK_ACCOUNT_COVERAGE) {
                    CDdAccountHelperMethods.handleCheckAccountCoverage(typeEvents);
                }
                else if (eType == PlatformEventType.OPP_BIZ_VERIFICATION_DOC_ATTACHED) {
                    CDdMerchantDocumentHelper.handleOpportunityUpdatesForBusinessVerificationDocument(typeEvents);
                }
                else if (eType == PlatformEventType.DISPATCH_LEAD_UPSERT) {
                    CDdDispatchRecordService.upsertLeads(typeEvents);
                }
                else if (eType == PlatformEventType.ACCOUNT_REPARENT) {
                    CDdAccountHelperMethods.handleAccountReparent(typeEvents);
                }
                else if (eType == PlatformEventType.ACCOUNT_ULTIMATE_PARENT){
                    CDdAccountHelperMethods.processUltimateParentEvents(typeEvents);
                }
                else if (eType == PlatformEventType.PHOTOSHOOT_CASE) {
                    CDdOpportunityCaseHelper.handleAsyncPhotoshootCase(typeEvents);
                }
                else if (eType == PlatformEventType.PROACTIVE_CASE_CREATION) {
                    CDdCaseEventHelper.handleProactiveCaseRecordCreation(typeEvents);
                }
                else if (eType == PlatformEventType.PROACTIVE_CASE_INFO_RECORD_CREATION) {
                    CDdCaseEventHelper.handleProactiveCaseInfoRecordCreation(typeEvents);
                }
                else if (eType == PlatformEventType.CREATE_CASE_FEED) {
                    CDdCaseEventHelper.createCaseFeedItem(typeEvents);
                }
                else if (eType == PlatformEventType.TEST_EVENT) {
                    // Do nothing for the test. Remember to keep this as the last when for test class coverage.
                }
            }
        }
    }
}