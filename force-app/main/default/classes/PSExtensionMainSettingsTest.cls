/**
 * @description Versioned as part of BZAP-13135. Pre-existing code for calling the PactSafeAPI.
 **/
@isTest
private class PSExtensionMainSettingsTest {

  @TestSetup
  static void setup(){
    Opportunity opty = TestPSHelpers.createTestOpportunity('Test', 'Acceptance');
    insert opty;
  }

  @isTest
  static void getContractNameMap() {
    Opportunity opty = [SELECT Id, Name, NextStep, StageName, closeDate FROM Opportunity WHERE NAME = 'Test' LIMIT 1];

    PSExtensionMainSettings settings = new PSExtensionMainSettings(opty.Id);
    settings.contractNameMappingData = 'Test';

    String mappingName = settings.getContractNameMap;

    Test.startTest();
    System.assertEquals(
      'Test',
      mappingName,
      'Expected to receive a contract name Test'
    );
    Test.stopTest();
  }

  @isTest
  static void getContractNameMapWithTestQuery() {
    Opportunity opty = [SELECT Id, Name, NextStep, StageName, closeDate FROM Opportunity WHERE NAME = 'Test' LIMIT 1];

    PSExtensionMainSettings settings = new PSExtensionMainSettings(opty.Id);
    settings.settingsMappings = TestPSHelpers.getTestMainSettingsContractNameMapping();

    String mappingName = settings.getContractNameMap;

    System.assertEquals(
      opty.Id,
      mappingName,
      'Expected to receive a contract name Test'
    );
  }

  @isTest
  static void getContractNameNegative() {
    Opportunity opty = [SELECT Id, Name, NextStep, StageName, closeDate FROM Opportunity WHERE NAME = 'Test' LIMIT 1];

    PSExtensionMainSettings settings = new PSExtensionMainSettings(opty.Id);
    String contractMapping = settings.getContractNameMap;

    System.assertEquals(
      '',
      contractMapping,
      'Expected to not receive a contract name mapping.'
    );
  }

  @isTest
  static void testGetErrorMessage() {
    Opportunity opty = [SELECT Id, Name, NextStep, StageName, closeDate FROM Opportunity WHERE NAME = 'Test' LIMIT 1];

    PSExtensionMainSettings settings = new PSExtensionMainSettings(opty.Id);
    settings.errorMessageData = 'My Error Message';

    String errorMessage = settings.getErrorMessage;

    Test.startTest();
    System.assertEquals(
      'My Error Message',
      errorMessage,
      'Expected to receive error message "My Error Message"'
    );
    Test.stopTest();
  }

}