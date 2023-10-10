/**
* @author Ed
* @date 2021-06
* @description BZAP-11027, 11032 Helper class for Vertical Categories
*/
public class CDdVerticalCategoryTriggerHandler {

    public static Vertical_Category_Trigger_Setting__c verticalCatFeatureFlags = Vertical_Category_Trigger_Setting__c.getOrgDefaults();

    public void beforeDelete(Map<Id, Vertical_Category__c> oldMap) {
        validateDelete(oldMap.values());
    }

    /**
    * @description Prevent delete if there is existing junction record. Also deletes associated custom setting
    **/
    public void validateDelete(List<Vertical_Category__c> oldList) {
        Integer junctionCount = 0;
        Id currVertCatId;
        List<Vertical_Category_Ids__c> vertCatSettingsList = new List<Vertical_Category_Ids__c>();
        for (Vertical_Category__c currVertCat : oldList) {
            currVertCatId = currVertCat.Id;
            // query in loop is fine because bulk delete is not expected
            junctionCount = database.countQuery('SELECT count() FROM Merchant_Category__c where Vertical_Category__c =:currVertCatId');
            if (junctionCount > 0 && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                currVertCat.addError(Label.VC_Delete_Validation);
            }
            junctionCount = 0;

            if (Vertical_Category_Ids__c.getValues(currVertCat.Name) != null) {
                vertCatSettingsList.add(Vertical_Category_Ids__c.getValues(currVertCat.Name));
            }
        }
        if (vertCatSettingsList.size() > 0) {
            delete vertCatSettingsList;
        }
    }
}