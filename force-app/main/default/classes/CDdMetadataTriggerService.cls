/**
 * @author: Raju Lakshman
 * @date: Feb 2021
 * @description: Service class providing the CDdMetadataTriggerHandler class with info about which classes to execute.
 * @Source https://github.com/trailheadapps/apex-recipes/blob/main/force-app/main/default/classes/Trigger%20Recipes/MetadataTriggerService.cls
 */

public without sharing class CDdMetadataTriggerService {
    public class MetadataTriggerServiceException extends Exception {}

    private String objType = '';
    private static final String USER_PROFILE_ID = 'User ProfileId';
    private static final String USER_EMAIL = 'User Email';
    private static final String USER_ID = 'User Id';

    public CDdMetadataTriggerService(String objectTypeName) {
        this.objType = objectTypeName;
    }

    /**
     * @description This query finds an ordered list trigger handler classes
     * to execute. It ignores any classes that are marked as disabled.
     *
     * Note: It will exclude any triggerHandler metadata records for which
     * the user's email address is found in a related disabled_for__mdt
     * record.
     *
     * Admin's and Developers can selectively disable trigger handlers
     * for all or selected individuals *without* deploying.
     * @return      `List<Metadata_Driven_Trigger__mdt>`
     */
    public List<Metadata_Driven_Trigger__mdt> getMetadataTriggers() {
        Set<String> metadataDrivenTriggerIdsToIgnore = new Set<String>();
        for (Metadata_Driven_Trigger_Disabled_For__mdt disabledFor :
                [SELECT Type__c,Detail__c,Metadata_Driven_Trigger__c,Metadata_Driven_Trigger__r.Object_API_Name__c
                   FROM Metadata_Driven_Trigger_Disabled_For__mdt
                  WHERE isActive__c = TRUE
                    AND Metadata_Driven_Trigger__r.isEnabled__c = TRUE
                    AND Metadata_Driven_Trigger__r.Object_API_Name__c = :this.objType]) {

            Boolean userIdMatch = disabledFor.Type__c == USER_ID && UserInfo.getUserId().containsIgnoreCase(disabledFor.Detail__c);
            Boolean userEmailMatch = disabledFor.Type__c == USER_EMAIL && disabledFor.Detail__c.equalsIgnoreCase(UserInfo.getUserEmail());
            Boolean userProfileIdMatch = disabledFor.Type__c == USER_PROFILE_ID && UserInfo.getProfileId().containsIgnoreCase(disabledFor.Detail__c);

            if (userIdMatch || userEmailMatch || userProfileIdMatch) {
                metadataDrivenTriggerIdsToIgnore.add(disabledFor.Metadata_Driven_Trigger__c);
            }
        }

        return metadataDrivenTriggerIdsToIgnore.isEmpty() ?
            [SELECT Class__c
               FROM Metadata_Driven_Trigger__mdt
              WHERE Object_API_Name__c = :this.objType
                AND isEnabled__c = TRUE
           ORDER BY Execution_Order__c] :
            [SELECT Class__c
               FROM Metadata_Driven_Trigger__mdt
              WHERE Object_API_Name__c = :this.objType
                AND isEnabled__c = TRUE
                AND Id NOT IN :metadataDrivenTriggerIdsToIgnore
           ORDER BY Execution_Order__c];
    }

    /**
     * @description This determines the active sObject type by describing the first
     * record in the trigger New / Old list
     * @return      `String`
     */
    public static String getSObjectType() {
        if (Trigger.new != null) {
            return Trigger.new[0].getSObjectType().getDescribe().getName();
        } else if (Trigger.old != null) {
            return Trigger.old[0].getSObjectType().getDescribe().getName();
        }
        throw new MetadataTriggerServiceException(
            'Trigger.new && Trigger.old are both null. Are you excercising this method outside of a trigger context?'
        );
    }
}