/**
*/
/********************************************************************************************************************
* @author Praveen
* @date 29/06/2022
*
* @group Merchant Services
*
* Class used to serialize a single Lookup search result item
* The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
*
**************************************************************************************************************************************/

public virtual class CDdMxEquipmentLookupSearchModel {
    @AuraEnabled
    public Id id;
    @AuraEnabled
    public String sObjectType;
    @AuraEnabled
    public String icon;
    @AuraEnabled
    public String title;
    @AuraEnabled
    public String subtitle;
    @AuraEnabled
    public String IMEIObject;
    @AuraEnabled
    public Boolean emailOrPhoneisnull;
    @AuraEnabled
    public String oppOrdorProtocol;
    @AuraEnabled
    public String platform;
    
    public CDdMxEquipmentLookupSearchModel() {
    }
    /**
    * @Descriptoin Methods takes table name from parent equipment request component and returns the table columns from metadata and data from query.
    * @param Id Id
    * @param sObjectType
    * @param string icon
    * @param string title
    * @param string subtitle
    * @param string IMEIObject
    * @return DataTableResponse
    */
    
    public CDdMxEquipmentLookupSearchModel(Id id, String sObjectType, String icon, String title, String subtitle, String IMEIObject, Boolean requiredContactFieldisnull) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.IMEIObject = IMEIObject;
        this.emailOrPhoneisnull = requiredContactFieldisnull;
    }
}