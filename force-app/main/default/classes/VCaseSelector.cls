public with sharing class VCaseSelector {
	public static List<Case> retrieveCases(Set<ID> caseIds, List<String> fields) {
		String query = 'select {0} from Case where Id in :caseIds';

		query = query.replace('{0}', String.join(fields, ','));

		return (List<Case>)Database.query(query);
	}

	public static List<Case> retrieveUsingDispatchAPIMappings(Set<ID> caseIds, List<String> staticFields) {
		String query = 'select {0} from Case where Id in :caseIds';

		List<String> fieldList = new List<String>();
		if(staticFields != null) {
			fieldList.addAll(staticFields);
		}

		for(DispatchCaseAPIFieldMapping__mdt mapping : [select Id, SFField__c
			from DispatchCaseAPIFieldMapping__mdt
			where IsActive__c = true]) {
			fieldList.add(mapping.SFField__c);
		}

		query = query.replace('{0}', String.join(fieldList, ','));
		System.debug(query);
		return (List<Case>)Database.query(query);
	}
}