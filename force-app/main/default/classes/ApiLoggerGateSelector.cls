public inherited sharing class ApiLoggerGateSelector extends fflib_SObjectSelector implements IApiLoggerGateSelector {
    /**
    * @description default constructor for the Api Logger Gate selector
    * @return  - interface of ApiLoggerGateSelector
    */
   public static IApiLoggerGateSelector newInstance() {
       return (IApiLoggerGateSelector) Application.Selector.newInstance(Api_Logger_Gate__c.SObjectType);
   }

   /**
    * @description This method is for getting the fields on this object
    * @return List of Schema.SObjectField
    */
   public List<Schema.SObjectField> getSObjectFieldList() {
       return new List<Schema.SObjectField>{
            Api_Logger_Gate__c.Id
       };
   }

   /**
    * @description This method is used for getting Object type
    * @return Schema.SObjectType
    */
   public Schema.SObjectType getSObjectType() {
       return Api_Logger_Gate__c.SObjectType;
   }

   /**
     * @description This method is to get the Org Default of the custom setting
     * @param None
     * @return Api_Logger_Gate__c - the Org Default
     */
    public Api_Logger_Gate__c getOrgDefaults() {
        return Api_Logger_Gate__c.getOrgDefaults();
    }

    /**
     * @description This method is to get the Instance record of the custom setting
     * @param None
     * @return Api_Logger_Gate__c - the Instance record
     */
    public Api_Logger_Gate__c getInstance() {
        return Api_Logger_Gate__c.getInstance();
    }
}