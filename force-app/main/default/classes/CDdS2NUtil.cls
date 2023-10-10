/**
 * Created by Jeremy S. Johnson, Perficient, Inc. on 2/25/2020.
 *
 * Utility class for working with Send to Nimda Platform Events.
 */
public with sharing class CDdS2NUtil {
    private static final String DD_USER = CDdNimdaSyncMSService.getDDUser();
    //TODO: Make this a Map of Maps, keyed by API, to support multiple S2N APIs
    private static Map<String, Uploader_Field_Map__mdt> fieldMap;

    public static Map<String, Uploader_Field_Map__mdt> getFieldMap() {
        if(fieldMap == null) {
            fieldMap = new Map<String, Uploader_Field_Map__mdt>();
            for (Uploader_Field_Map__mdt mdt : [SELECT Object__c, Field__c, Type__c 
                                                FROM Uploader_Field_Map__mdt
                                                WHERE Is_Permissible__c = true 
                                                ORDER BY Object__c, Field__c]) {
                fieldMap.put(mdt.Object__c + '.' + mdt.Field__c, mdt);
            }
        }
        return fieldMap;
    }

    public static Boolean isPermissibleField(String objectFieldName) {
        return getFieldMap().keySet().contains(objectFieldName);
    }

    public static Map<String, String> S2N_STORE_PARTNERSHIP_MAPPING = new Map<String, String> {
            // TODO: derive this from custom metadata
            'Opportunity.Commission__c'                         => 'commission_rate',
            'Opportunity.DashPass_Flat_Fee__c'                  => 'subscription_flat_fee',
            'Opportunity.Dashpass_Only_Commission__c'           => 'subscription_commission_rate',
            'Opportunity.In_App_Pickup_Commission__c'           => 'pickup_commission_rate',
            'Opportunity.Inflation__c'                          => 'inflation_rate',
            'Opportunity.Inflation_Rounding_Unit__c'            => 'inflation_rounding_unit',
            'Opportunity.Referred_Delivery_Commission__c'       => 'reduced_commission_rate',
            'Opportunity.Referred_Pickup_Commission__c'         => 'reduced_pickup_commission_rate',
            'Opportunity.Service_Fee_New__c'                    => 'service_rate',
            'Opportunity.Weekly_Printer_Subscription_Fee__c'    => 'weekly_printer_subscription_fee',
            'Opportunity.Weekly_Tablet_Subscription_Fee__c'     => 'weekly_tablet_subscription_fee'
    };

    public static MSSyncStage msSyncStageFromString(String msSyncStageStr) {
        MSSyncStage stage = MSSyncStage.Undefined;

        switch on msSyncStageStr {
            when 'Create Merchant'                  { stage = MSSyncStage.CreateMerchant; }
            when 'Create Store'                     { stage = MSSyncStage.CreateStore; }
            when 'Create User'                      { stage = MSSyncStage.CreateUser; }
            when 'Full Onboarding Create'           { stage = MSSyncStage.FullOnboardingCreate; }
            when 'Full Onboarding Update'           { stage = MSSyncStage.FullOnboardingUpdate; }
            when 'Payment Account'                  { stage = MSSyncStage.PaymentAccount; }
            when 'Stripe Bank Account'              { stage = MSSyncStage.StripeBankAccount; }
            when 'Stripe Bank Token'                { stage = MSSyncStage.StripeBankToken; }
            when 'Update Store'                     { stage = MSSyncStage.UpdateStore; }
            when 'Product and Pricing Onboarding'   { stage = MSSyncStage.ProductAndPricingOnboarding; }
        }

        return stage;
    }

    public static String msSyncStageFromEnum(MSSyncStage msSyncStageEnum) {
        String stage = 'Undefined';

        switch on msSyncStageEnum {
            when CreateMerchant                 { stage = 'Create Merchant'; }
            when CreateStore                    { stage = 'Create Store'; }
            when CreateUser                     { stage = 'Create User'; }
            when FullOnboardingCreate           { stage = 'Full Onboarding Create'; }
            when FullOnboardingUpdate           { stage = 'Full Onboarding Update'; }
            when PaymentAccount                 { stage = 'Payment Account'; }
            when StripeBankAccount              { stage = 'Stripe Bank Account'; }
            when StripeBankToken                { stage = 'Stripe Bank Token'; }
            when UpdateStore                    { stage = 'Update Store'; }
            when ProductAndPricingOnboarding    { stage = 'Product and Pricing Onboarding'; }
        }

        return stage;
    }

    /**
     * Used by Batchable version of Bulk Uploader to send events for a list of potentially related SObjects.
     *
     * @param ctx
     * @return Boolean: True if events published successfully
     */
    public static void sendEvents(CDdUploaderContext ctx) {
        List<SObject> events = new List<SObject>();

        switch on ctx.msSyncStageEnum {
            when FullOnboardingCreate, FullOnboardingUpdate, CreateStore, UpdateStore {     // Store_Onboarding_Event__e
                for (Map<Id, SObject> objects : ctx.updateListByGroup.values()) {           // outer Map (parents)
                    for (SObject obj : objects.values()) {                                  // inner Map (parent + children)
                        Boolean isAccount = 'Account'.equals(obj.getSObjectType().getDescribe().getName());
                        Boolean isParent = ctx.isCompositeUpdate && isAccount;
                        if (!isParent) {
                            Store_Onboarding_Event__e event = new Store_Onboarding_Event__e();
                            event.AccountId__c = isAccount ? (String) obj.get('Id') : (String) obj.get('AccountId');
                            event.OpportunityId__c = isAccount ? null : (String) obj.get('Id');
                            event.PrimaryQuote__c = (String) obj.get(CDdUploaderConstants.OPPORTUNITY_FIELD_API_NAME_PRIMARY_QUOTE_ID);
                            event.MS_Sync_Stage__c = ctx.msSyncStageStr;
                            //BZAP-9643 - default Do_Change_Fields_Incl_Store_Partnership__c to true
                            //event.Do_Change_Fields_Incl_Store_Partnership__c = isStorePartnership(ctx.columns);
                            event.Do_Change_Fields_Incl_Store_Partnership__c = true;
                            event.Origin__c = System.Label.Nimda_Origin_Bulk_Uploader;
                            event.User_Email__c = DD_USER;
                            event.User_Id__c = UserInfo.getUserId();
                            System.debug('CDdS2NUtil.sendEvents, event: ' + event);
                            events.add(event);
                        }
                    }
                }
            }
            when ProductAndPricingOnboarding {
                for (Map<Id, SObject> objects : ctx.updateListByGroup.values()) {           // outer Map (parents)
                    for (SObject obj : objects.values()) {                                  // inner Map (parent + children)
                        Boolean isAccount = 'Account'.equals(obj.getSObjectType().getDescribe().getName());
                        Boolean isParent = ctx.isCompositeUpdate && isAccount;
                        if (!isParent) {
                            Store_Onboarding_Event__e event = new Store_Onboarding_Event__e();
                            event.AccountId__c = isAccount ? (String) obj.get('Id') : (String) obj.get('AccountId');
                            event.OpportunityId__c = isAccount ? null : (String) obj.get('Id');
                            event.PrimaryQuote__c = (String) obj.get(CDdUploaderConstants.OPPORTUNITY_FIELD_API_NAME_PRIMARY_QUOTE_ID);
                            event.MS_Sync_Stage__c = msSyncStageFromEnum(MSSyncStage.FullOnboardingUpdate);
                            event.MS_Changed_Fields__c = String.join(CDdNimdaSyncOnboardingConfigHelper.getAllFieldProperties(ctx.msSyncStageStr),',');
                            event.Do_Change_Fields_Incl_Store_Partnership__c = true;
                            event.Origin__c = System.Label.Nimda_Origin_Bulk_Uploader;
                            event.User_Email__c = DD_USER;
                            event.User_Id__c = UserInfo.getUserId();
                            System.debug('CDdS2NUtil.sendEvents, event: ' + event);
                            events.add(event);
                        }
                    }
                }
            }            
            when else {
            }
        }

        publishEvents(ctx, events);
    }

    public static Boolean publishEvents(CDdUploaderContext ctx, List<SObject> events) {
        List<Database.SaveResult> results = EventBus.publish(events);

        List<String> errMsgs = new List<String>();
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    ctx.batchErrors.add(err.getMessage());
                    errMsgs.add(err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        }
        if (errMsgs.size() > 0) {
            CDdErrorUtilities.createApexLogs(errMsgs, 'CDdUploaderBatch', 'sendOnboardingEvent', LoggingLevel.ERROR);
        }

        return errMsgs.size() == 0;
    }
    //BZAP-9643 - default Do_Change_Fields_Incl_Store_Partnership__c to true
    /*public static Boolean isStorePartnership(List<String> fieldNames) {
        for(String field : fieldNames) {
            if(S2N_STORE_PARTNERSHIP_MAPPING.containsKey(field)) {
                return true;
            }
        }
        return false;
    }*/
}