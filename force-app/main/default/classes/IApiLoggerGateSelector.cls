public interface IApiLoggerGateSelector extends fflib_ISObjectSelector {
    /**
     * @description This method is to get the Org Default of the custom setting
     * @param None
     * @return Api_Logger_Gate__c - the Org Default
     */
    Api_Logger_Gate__c getOrgDefaults();

    /**
     * @description This method is to get the Instance record of the custom setting
     * @param None
     * @return Api_Logger_Gate__c - the Instance record
     */
    Api_Logger_Gate__c getInstance();
}