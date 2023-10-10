@isTest
public class CDdGDPRGetConsentFieldsTest {

    static testmethod void testValidComplianceFieldSet(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;
        CDdGDPRGetConsentFieldSet.getData(caseList[0].Id,'CRMC_PP__CRMC_Action_Grid_Defaults','Case_Consent_Field');
    }
     static testmethod void testInvalidComplianceFieldSetName(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;
        CDdGDPRGetConsentFieldSet.getData('','Consent_Fields','Case_Consent_Field');

    }
     static testmethod void testBlankComplianceFieldSet(){
        List<Case> caseList = TDdCaseFactory.createCaseRecords(1, 'Support');
        insert caseList;

        CDdGDPRGetConsentFieldSet.getData(caseList[0].Id,'','Case_Consent_Field');
    }



}