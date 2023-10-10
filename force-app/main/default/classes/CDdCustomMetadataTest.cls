@isTest

public class CDdCustomMetadataTest {

    // Custom Metadata Test methods for Batch and Trigger Settings -- Batch_and_Trigger_Setting__mdt

    public static testMethod void getBatchAndTriggerSettingsTest() {
        Batch_and_Trigger_Setting__mdt setting = null;
        system.assertEquals(CDdCustomMetadata.defaultBatchSize,CDdCustomMetadata.getBatchSize(setting));
        system.assertEquals(CDdCustomMetadata.defaultDisabled, CDdCustomMetadata.isDisabled(setting));
        system.assertEquals(CDdCustomMetadata.defaultRecursion,CDdCustomMetadata.getRecursion(setting));
        system.assertEquals(null,CDdCustomMetadata.getCustomNumber(setting));
        setting = new Batch_and_Trigger_Setting__mdt();
        system.assertEquals(CDdCustomMetadata.defaultBatchSize,CDdCustomMetadata.getBatchSize(setting));
        system.assertEquals(CDdCustomMetadata.defaultDisabled, CDdCustomMetadata.isDisabled(setting));
        system.assertEquals(CDdCustomMetadata.defaultRecursion,CDdCustomMetadata.getRecursion(setting));
        system.assertEquals(null,CDdCustomMetadata.getCustomNumber(setting));
        system.assertEquals(100,CDdCustomMetadata.getBatchSize('CDdCustomMetadataTest'),
            'This test method needs Batch and Trigger Settings Metadata: CDdCustomMetadataTest, 100');
        system.assertEquals(false,CDdCustomMetadata.isDisabled(
            'CDdCustomMetadataTest'),'This test method needs Batch and Trigger Settings Metadata: CDdCustomMetadataTest, false');
        system.assertEquals(1,CDdCustomMetadata.getRecursion('CDdCustomMetadataTest'),
            'This test method needs Batch and Trigger Settings Metadata: CDdCustomMetadataTest, 1');
        system.assertEquals(256,CDdCustomMetadata.getCustomNumber('CDdCustomMetadataTest'),
            'This test method needs Batch and Trigger Settings Metadata: CDdCustomMetadataTest, 256');
        }

        // NOTE: No longer throwing an exception, just return the default (therefore only overrides need to be in the custom metadata)
        public static testMethod void getBatchMetadataExceptionTest() {
        try {
            Batch_and_Trigger_Setting__mdt settings = CDdCustomMetadata.getBatchAndTriggerMetadata('NoClass');
            system.assertEquals(null, settings, 'Settings should be null for something not defined in the metadata.');
        }
        catch (Exception eX) {
            system.assertEquals('Batch and Trigger Setting Metadata not found for: NoClass', eX.getMessage());
        }
    }

    public static testMethod void getProfileValuesTest() {
        system.assertEquals('123456789012345678', CDdCustomMetadata.getProfileValueFor('CDdCustomMetadataTest'));
    }

    public static testMethod void getBatchCaseCloseListTest() {
        List<Batch_Case_To_Close__mdt> batchList = CDdCustomMetadata.getBatchCaseCloseList();
        system.assertNotEquals(0, batchList.size());
    }

    public static testMethod void getIdValueTest() {
        system.assertEquals('1234567890abcde', CDdCustomMetadata.getIdValueFor('REQUIRED_FOR_UNIT_TESTS'));
    }

    public static testMethod void getUserLicenseListTest() {
        List<User_License__mdt> checkList = CDdCustomMetadata.getUserLicenseList();
        system.assertEquals(1, checkList.size(), 'Problem with required metadata.');
        List<Id> ProfileIDs = new List<Id>(CDdCustomMetadata.profileIDs(checkList[0].Profiles__c, ','));
    }

    public static testMethod void namesTest() {
        Set<String> names = CDdCustomMetadata.names('a, b, c', ',');
        system.assertEquals(3, names.size());
        system.assertEquals(true, names.contains('a'));
        system.assertEquals(false, names.contains('d'));
    }

    public static testMethod void getProfileLicenseMapTest() {
        system.assertNotEquals(null, CDdCustomMetadata.getProfileLicenseMap());
    }

    public static testMethod void getRoleLicenseMapTest() {
        system.assertNotEquals(null, CDdCustomMetadata.getRoleLicenseMap());
    }

}