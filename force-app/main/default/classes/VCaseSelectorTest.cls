@isTest
public with sharing class VCaseSelectorTest {
	@isTest
	static void testRetrieve() {
		insert VTestUtil.createVeltigSettings();
		Case c = new Case(Subject = 'Test');
		insert c;

		Set<ID> caseIds = new Set<ID>();
		caseIds.add(c.Id);

		System.assertEquals(1, VCaseSelector.retrieveCases(caseIds, new List<String> {'ChatKey__c'}).size());
	}

	@isTest
	static void testMetadataSelect() {
		insert VTestUtil.createVeltigSettings();
		Case c = new Case(Subject = 'Test');
		insert c;

		Set<ID> caseIds = new Set<ID>();
		caseIds.add(c.Id);

		System.assertEquals(1, VCaseSelector.retrieveUsingDispatchAPIMappings(caseIds, new List<String> {'ChatKey__c'}).size());
	}
}