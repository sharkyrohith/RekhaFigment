/**
 * @author Sanidhya Jain
 * @date 2023-08
 *
 * @description Class : BIZS-3185 Test class for CDdShowLightningRecordForm
*/
@isTest
public class CDdShowLightningRecordFormTest {
    //testSetup to create dumy data
    @testSetup
    public static void tesSetup(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;
    }

    //Method to check valid scenario when FieldSet Name is Empty
    @isTest
    static void testGetFieldsBlankFieldSetName(){
        CDdShowLightningRecordForm.FieldObjWrapper fieldOlbWrapper = new CDdShowLightningRecordForm.FieldObjWrapper();
        List<Case> caseList = new List<Case>();
        caseList = [Select id From Case Where RecordType.Name = 'Support'];
        test.startTest();
        fieldOlbWrapper = CDdShowLightningRecordForm.getFields(caseList[0].Id,'');
        test.stopTest();
        System.assertEquals(null, fieldOlbWrapper, 'fieldOlbWrapper should be empty');
    }

    //Method to check valid scenario when RecordId is incorrect
    @isTest
    static void testGetFieldsWongRecordId(){
        CDdShowLightningRecordForm.FieldObjWrapper fieldOlbWrapper = new CDdShowLightningRecordForm.FieldObjWrapper();
        test.startTest();
        fieldOlbWrapper = CDdShowLightningRecordForm.getFields('12345','CRMC_PP__CRMC_Action_Grid_Defaults');
        test.stopTest();
        System.assertEquals(null, fieldOlbWrapper, 'fieldOlbWrapper should be empty');
    }

    //Method to check valid scenario when FieldSet Name is incorrect
    @isTest
    static void testGetFieldsWongFieldSetName(){
        CDdShowLightningRecordForm.FieldObjWrapper fieldOlbWrapper = new CDdShowLightningRecordForm.FieldObjWrapper();
        List<Case> caseList = new List<Case>();
        caseList = [Select id From Case Where RecordType.Name = 'Support'];
        test.startTest();
        fieldOlbWrapper = CDdShowLightningRecordForm.getFields(caseList[0].Id,'CRMC_PP__CRMC_Action_Grid_Defau');
        test.stopTest();
        System.assertEquals(null, fieldOlbWrapper, 'fieldOlbWrapper should be empty');
    }

     //Method to check valid scenario when FieldSet Name & RecordId are correct
    @isTest
    static void testGetFieldsValid(){
        CDdShowLightningRecordForm.FieldObjWrapper fieldOlbWrapper = new CDdShowLightningRecordForm.FieldObjWrapper();
        List<Case> caseList = new List<Case>();
        caseList = [Select id From Case Where RecordType.Name = 'Support'];
        test.startTest();
        fieldOlbWrapper = CDdShowLightningRecordForm.getFields(caseList[0].Id,'CRMC_PP__CRMC_Action_Grid_Defaults');
        test.stopTest();
        System.assert(fieldOlbWrapper != null, 'fieldOlbWrapper should not be empty');
    }
}