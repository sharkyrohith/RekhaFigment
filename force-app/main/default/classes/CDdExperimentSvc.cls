/**
 * 
 * @author: Tia Xuan
 * @date: 2019-06
 * @description class for CDdExperimentSvc 
 * 				helper class for feature flag metadata
 * 
 */

public class CDdExperimentSvc {
    /**
    * @description get feature flag by name
    * @param flagName name of field on the DDFeatureFlag metadata
    * @return Boolean value of the feature flag, or error 	
    **/
    public static Boolean getFeatureFlag(String flagName){

        String profileId = UserInfo.getProfileId();

        // BZAPSUP-2030 Tia Xuan 06/2021 Use getAll for metadata
        List<DDFeatureFlag__mdt> retVals = DDFeatureFlag__mdt.getAll().values();

        DDFeatureFlag__mdt retVal = null;
        DDFeatureFlag__mdt defaultVal = null;

        for (DDFeatureFlag__mdt ff : retVals){
            if (ff.Profile_ID__c  ==  profileId ){
                retVal = ff;
            } else if(ff.MasterLabel == 'Default'){
                defaultVal = ff;
            } 
        }   

        if (retVal == null){
            return (Boolean) defaultVal.get(flagName);
        } else {
            return (Boolean) retVal.get(flagName);
        }
    }

    /**
    * @description get support feature flag by name
    * @param flagName name of field on the Support_Feature_Flag__c custom Setting
    * @return Boolean value of the support feature flag, or error 	
    **/
    public static Boolean getSupportFeatureFlag(String flagName){
        Support_Feature_Flag__c retVal = Support_Feature_Flag__c.getInstance();
        if (retVal != null){
            return (Boolean) retVal.get(flagName) != null ? (Boolean) retVal.get(flagName) : false;
        } else {
            return false;
        }
    }


    /**
     * @description get percentage based experiment flag from Support_Feature_Flag__c Custom Setting
     *                  Utilizes random number generator to get a number divide by integer. 
     *                  Returns TRUE If remainder is 0, else FALSE. 
     * @author      Jeegar
     * @param       flagName name of number field on the Support_Feature_Flag__c custom setting
     * @return      Boolean Should the code be executed or not based on percentage flag. 
     */
    public static boolean getSupportPercentageBasedExperimentFlag(String flagName){
        Support_Feature_Flag__c supportFeatureFlag = Support_Feature_Flag__c.getInstance(); 
        if(supportFeatureFlag != null) {
            return percentageBasedExperimentFlag(Integer.valueOf(supportFeatureFlag.get(flagName))); 
        } else {
            return false;
        }
    }

    /**
    * @description get feature flag by name
    * @param flagName name of field on the Feature_Flags__c custom Setting
    * @return Boolean value of the support feature flag, or error
    **/
    public static Boolean getCustomSettingFeatureFlag(String flagName){
        Feature_Flags__c retVal = Feature_Flags__c.getInstance();
        if (retVal != null){
            return (Boolean) retVal.get(flagName) != null ? (Boolean) retVal.get(flagName) : false;
        } else {
            return false;
        }
    }

    /**
     * @description Returns boolean based on input. Utilizes random number generator to get a number divide by integer. 
     *                 Returns TRUE If remainder is 0, else FALSE. 
     * @author      Jeegar
     * @param       Integer activePercentage 
     * @return      Boolean value based on random number generator. 
     */
    public static boolean percentageBasedExperimentFlag(Integer activePercentage) {
        Integer randomNumber = Math.abs(Crypto.getRandomInteger()); 
        if(activePercentage == null || activePercentage <= 0) {
            return false; 
        }
        activePercentage = (activePercentage > 100 ? 100 : activePercentage); 
        Integer divisor = Integer.valueOf(100/activePercentage);
        Integer remainder = Math.Mod(randomNumber,divisor);
        if(remainder == 0){
            return true;
        }
        return false; 
    }

    // Method to call the validateRun directly without having to leverage
    // the entire TriggerHandler framework.
    public static Boolean canRun(String customSettingFlagName) {
        return validateRun(customSettingFlagName);
    }

    /**
     * @description make sure this trigger should continue to run
     * @return     `Boolean`
     * @exception   CDdTriggerHandlerException thrown when executing outside of a trigger
     */
    @TestVisible
    public static Boolean validateRun(String customSettingFlagName) {
        Disable_Trigger_Code__c settings = Disable_Trigger_Code__c.getInstance();
        if (String.isNotBlank(customSettingFlagName) && settings != null) {
            Boolean disableTrigger = (Boolean)settings.get(customSettingFlagName);
            // Refer Salesforce Case 42759685. When new checkbox custom setting field is created, its not immediately available to the cache - so accessing the field throws an NPE.
            if (disableTrigger != null && disableTrigger) {
                return false;
            }
        }

        return true;
    }

}