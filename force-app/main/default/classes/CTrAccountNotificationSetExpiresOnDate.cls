/**
 * @author: Raju Lakshman
 * @date: May 2023
 * @description Sets "Notification Expires On" Date conditionally
 */
public without sharing class CTrAccountNotificationSetExpiresOnDate extends CDdTriggerHandler {

    /**
     * @description Constructor
     */
    public CTrAccountNotificationSetExpiresOnDate() {}

    /**
     * @description Overriden event handlers..
     */
    public override void beforeInsert() {
        setDefaultValuesOnFields();
    }

    public override void beforeUpdate() {
        setDefaultValuesOnFields();
    }

    /**
     * @description Depending on Type, this conditionally sets the expires on date if not provided by the user.
     */
    @TestVisible
    private void setDefaultValuesOnFields() {
        List<Account_Notification__c> recList = (List<Account_Notification__c>)triggerList;
        Map<Id,Account_Notification__c> recOldMap = (Map<Id,Account_Notification__c>)triggerOldMap;
        Boolean isInsert = getTriggerContext() == TriggerContext.BEFORE_INSERT;
        Map<String,Account_Notification_Message__mdt> accountNotificationMessageMap =
            AccountNotificationSelector.newInstance().getAccountNotificationMessagesByType(true);

        for (Account_Notification__c rec : recList) {
            Boolean expiresOnBlankOnInsert = isInsert && rec.Active__c && rec.Notification_Expires_On__c == null;
            Boolean severityOnBlankOnInsert = isInsert && rec.Active__c && String.isBlank(rec.Severity__c);
            Boolean dismissableBlankOnInsert = isInsert && rec.Active__c && !rec.Is_Notification_Dismissable__c;
            Boolean activeSet = !isInsert && isFieldUpdated(rec,recOldMap,'Active__c') && rec.Active__c;
            Boolean typeSet = !isInsert && isFieldUpdated(rec,recOldMap,'Type__c') && rec.Active__c;

            if (accountNotificationMessageMap.containsKey(rec.Type__c)) {
                Account_Notification_Message__mdt accNotifMsg = accountNotificationMessageMap.get(rec.Type__c);
                if (expiresOnBlankOnInsert || activeSet || typeSet) {
                    if (accNotifMsg.Notification_Ends_On__c != null) {
                        rec.Notification_Expires_On__c = accNotifMsg.Notification_Ends_On__c;
                    }
                    if (accNotifMsg.Notification_Ends_After_Days__c != null) {
                        rec.Notification_Expires_On__c = System.today().addDays(Integer.valueOf(accNotifMsg.Notification_Ends_After_Days__c));
                    }
                }
                if (severityOnBlankOnInsert || activeSet || typeSet) {
                    rec.Severity__c = accNotifMsg.Severity__c;
                }
                if (dismissableBlankOnInsert || activeSet || typeSet) {
                    rec.Is_Notification_Dismissable__c = accNotifMsg.Is_Notification_Dismissable__c;
                }
            }
            if (String.isBlank(rec.Severity__c)) {
                rec.Severity__c = 'Info';
            }
        }
    }
}