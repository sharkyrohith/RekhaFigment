/**
 * CDdLightningUtils
 * @ticket https://doordash.atlassian.net/browse/BASD-15507
 * @author Mahesh Chouhan
 * @date  4 feb 2022
 * @decription Utility class for Salesforce Lightning Interface
 */
public class CDdLightningUtils {

    /**
    * @author Mahesh Chouhan
    * @date  4 feb 2021
    * @decription Returns the UI theme being displayed for the current user
    * @params None
    * @return String specifying the UI theme being displayed for the current user
    */
    @AuraEnabled(cacheable=true)
    public static String getUiThemeDisplayed() {
        return UserInfo.getUiThemeDisplayed();
    }

      /**
     * @author Raju Lakshman
     * @date  Sept 2022
     * @decription Returns "Standard" or "Console" based on the current user's LE
     * @params None
     * @return "Standard" or "Console" based on the current user's LE
     */
    @AuraEnabled(cacheable=true)
    public static String getNavType() {
        List<UserAppInfo> userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
        List<AppDefinition> appDefinition = userAppInfo.isEmpty() ?
            null : [SELECT DurableId, NavType FROM AppDefinition WHERE DurableId = :userAppInfo[0].AppDefinitionId LIMIT 1];
        return appDefinition == null || appDefinition.isEmpty() ? 'Standard' : appDefinition[0].NavType;
    }
}