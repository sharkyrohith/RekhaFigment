public with sharing class VObjectUtil {
	public static Set<ID> extractIds(List<sObject> sobjList) {
		Set<ID> res = new Set<ID>();

		for(sObject sobj : sobjList) {
			res.add(sobj.Id);
		}
		
		return res;
	}
}