/**
 * @author Knick
 * @date 7/2020
 * @description Test Class for Generic Platform Event creation, publishing and handling
**/
@isTest
public class CDdGenericPlatformEventHelperTest {
    @isTest
    public static void testGenericPlatformEvents() {
        Integer testSize = 2;
        List<Account> accounts = TDdAccountFactory.createAccounts('Test', testSize);
        insert accounts;
        List<Id> accountIds = new List<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }
        test.startTest();
            CDdGenericPlatformEventHelper.PlatformEventType eventType = CDdGenericPlatformEventHelper.PlatformEventType.TEST_EVENT;
            List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(eventType, accountIds);
            system.assertEquals(testSize, eList.size());
            CDdGenericPlatformEventHelper.publishEvents(eventType, AccountIds);
            test.getEventBus().deliver();
        test.stopTest();
    }

    @isTest
    public static void testGenericPlatformEvents_OldLogic() {
        Feature_Flags__c ftrFlag = Feature_Flags__c.getOrgDefaults();
        ftrFlag.Disable_Upgraded_Generic_Platform_Event__c = true;
        insert ftrFlag;
        Integer testSize = 2;
        List<Account> accounts = TDdAccountFactory.createAccounts('Test', testSize);
        insert accounts;
        List<Id> accountIds = new List<Id>();
        for (Account a : accounts) {
            accountIds.add(a.Id);
        }
        test.startTest();
            CDdGenericPlatformEventHelper.PlatformEventType eventType = CDdGenericPlatformEventHelper.PlatformEventType.TEST_EVENT;
            List<Generic_Platform_Event__e> eList = CDdGenericPlatformEventHelper.createEvents(eventType, accountIds);
            system.assertEquals(testSize, eList.size());
            CDdGenericPlatformEventHelper.publishEvents(eventType, AccountIds);
            test.getEventBus().deliver();
        test.stopTest();
    }
}