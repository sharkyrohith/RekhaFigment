public with sharing class VDispatchCaseSerializer {
	private static List<DispatchCaseAPIFieldMapping__mdt> DISPATCH_FIELD_MAPPING;

	static {
		DISPATCH_FIELD_MAPPING =  [select Id, SFField__c, DispatchField__c
			from DispatchCaseAPIFieldMapping__mdt
			where IsActive__c = true];

		System.debug(DISPATCH_FIELD_MAPPING);
	}

	public static String serialize(Case cse) {
		Map<String, Object> output = new Map<String, Object>();

		for(DispatchCaseAPIFieldMapping__mdt mapping : DISPATCH_FIELD_MAPPING) {
			String sfField = mapping.SFField__c;
			String dispatchField = mapping.DispatchField__c;

			Object val = cse.get(sfField);

			if(val != null && String.valueOf(val).isAlpha()) {
				val = ((String)val).toLowerCase();
			}
			
			output.put(dispatchField, val);
		}

		if(output.containsKey('case_status')) {
			String status = (String)output.get('case_status');

			// Due to workflow rule Open may be in status when we are sending as "New"
			// replace it.
			if(status == 'Open' && !cse.IsSentToDispatch__c) {
				output.put('case_status', 'new');
			}
		}

		System.debug(output);

		return JSON.serialize(output);
	}
}