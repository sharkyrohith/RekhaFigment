/**
 * @author Raju Lakshman
 * @date March 2022
 * @description Test class for the CDdTriggerHandler and CDdMetadataTriggerHandler Framework
 *
 *              This uses the dummy abc__c object trigger.
 */

@isTest
public class CDdTriggerHandlerTest {
    static void createDisableTriggerCodeRecord(Boolean value) {
        Disable_Trigger_Code__c rec = new Disable_Trigger_Code__c(
            SetupOwnerId = UserInfo.getUserId(),
            abc__c = value
        );
        upsert rec;
    }

    @IsTest
    static void testCDdTriggerHandlerFramework(){
        createDisableTriggerCodeRecord(false);
        abc__c testRec1 = new abc__c();
        insert testRec1;
        List<abc__c> records = getRecords(testRec1.Id);
        System.assert(records[0].Name.startsWith('abc'), 'Name does not start with abc');
        testRec1.New_Field__c = true;
        update testRec1;
        records = getRecords();
        system.assertEquals(2, records.size(), 'Record Size does not match expected');
        try {
            delete testRec1;
            system.assert(false,'Record Delete was successful -- this is not expected.');
        } catch(Exception e) {
            system.assert(true,'Record Delete was not successful -- this is expected.');
        }
        testRec1.New_Field__c = false;
        update testRec1;
        try {
            delete testRec1;
            system.assert(true,'Record Delete was successful -- this is expected.');
        } catch(Exception e) {
            system.assert(false,'Record Delete was not successful -- this is not expected.');
        }
        undelete testRec1;
        records = getRecords();
        system.assertEquals(2, records.size(), 'Record Size does not match expected');
    }

    @IsTest
    static void testCDdMetadataTriggerHandlerFramework2(){
        createDisableTriggerCodeRecord(false);
        CDdTriggerHandler.TEST_CLASS_USE_METADATA_FRAMEWORK = true;
        abc__c testRec1 = new abc__c();
        insert testRec1;
        List<abc__c> records = getRecords(testRec1.Id);
        System.assert(records[0].Name.startsWith('abc'), 'Name does not start with abc');
        testRec1.New_Field__c = true;
        update testRec1;
        records = getRecords();
        system.assertEquals(2, records.size(), 'Record Size does not match expected');
        try {
            delete testRec1;
            system.assert(false,'Record Delete was successful -- this is not expected.');
        } catch(Exception e) {
            system.assert(true,'Record Delete was not successful -- this is expected.');
        }
        testRec1.New_Field__c = false;
        update testRec1;
        try {
            delete testRec1;
            system.assert(true,'Record Delete was successful -- this is expected.');
        } catch(Exception e) {
            system.assert(false,'Record Delete was not successful -- this is not expected.');
        }
        undelete testRec1;
        records = getRecords();
        system.assertEquals(2, records.size(), 'Record Size does not match expected');
    }

    @IsTest
    static void testCustomSettingBypassFlag(){
        createDisableTriggerCodeRecord(true);
        abc__c testRec1 = new abc__c();
        testRec1.New_Field__c = true;
        insert testRec1;
        system.assertEquals(1, getRecords().size(), 'Record Size does not match expected');
    }

    @IsTest
    static void testDynamicBypass(){
        CDdTriggerHandler.bypass('CTrAbcTriggerHandler');
        abc__c testRec1 = new abc__c();
        testRec1.New_Field__c = true;
        insert testRec1;
        system.assertEquals(1, getRecords().size(), 'Record Size does not match expected');
        system.assertEquals(true,CDdTriggerHandler.isBypassed('CTrAbcTriggerHandler'),'Trigger bypass is false');
        CDdTriggerHandler.clearBypass('CTrAbcTriggerHandler');
        CDdTriggerHandler.clearAllBypasses();
    }

    @IsTest
    static void testMaxLoops(){
        createDisableTriggerCodeRecord(false);
        CDdTriggerHandler.TEST_CLASS_MAX_LOOP_COUNT = 1;
        try {
            abc__c testRec1 = new abc__c();
            testRec1.New_Field__c = true;
            insert testRec1;
            system.assert(false,'Record Insert was successful -- this is not expected.');
        } catch(Exception e) {
            system.assert(true,'Record Insert was not successful -- this is expected.');
        }
    }

    @IsTest
    static void increaseCodeCoverage(){
        CTrAbcTriggerHandler triggerHandler = new CTrAbcTriggerHandler();
        triggerHandler.setTriggerContext('after undelete',true);
        triggerHandler.setTriggerContext('after delete',true);
        triggerHandler.setTriggerContext('before delete',true);
        triggerHandler.setTriggerContext('after update',true);
        triggerHandler.setTriggerContext('before update',true);
        triggerHandler.setTriggerContext('after insert',true);
        triggerHandler.setTriggerContext('before insert',true);
        try {
            triggerHandler.setTriggerContext('wheels on the bus go round and round',true);
            system.assert(false,'Expected exception was not thown');
        } catch(CDdTriggerHandler.CDdTriggerHandlerException e) {
            system.assert(true,'Expected exception thrown');
        } catch(Exception e) {
            system.assert(false,'Expected exception was not thown');
        }
    }

    @IsTest
    static void testMetadataMethodBypass(){
        CDdTriggerHandler.TEST_CLASS_USE_METADATA_FRAMEWORK  = true;
        List<Profile> profiles = [SELECT Id FROM Profile WHERE NAME = 'Agent'];
        List<User> users = TDdUserFactory.createUsers(1,profiles[0].Id,null,false);
        system.runAs(users[0]) {
            createDisableTriggerCodeRecord(false);
            abc__c testRec1 = new abc__c();
            insert testRec1;
            List<abc__c> records = getRecords();
            system.debug(records);
            system.assertEquals(1, records.size(), 'Record Size does not match expected');
            system.assert(!records[0].name.startsWith('abc'), 'Name starts with abc - not expected');
        }
    }

    private static List<abc__c> getRecords() {
        return [SELECT Id,Name,New_Field__c FROM abc__c];
    }

    private static List<abc__c> getRecords(String recId) {
        return [SELECT Id,Name,New_Field__c FROM abc__c WHERE Id = :recId];
    }
}