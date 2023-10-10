/**
 * @description       : Utility class for Site Surveys
 * @author            : Jose Vega
 * @last modified on  : 03-13-2023
 * @last modified by  : Jose Vega
**/
public with sharing class SurveySitesUtil {

	public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

	public Boolean hasSites() {
		return SOBJECT_TYPES.keySet().contains('site');
	}

	public List<SurveySiteInfo> getSiteList() {

		List<SurveySiteInfo> ret = new List<SurveySiteInfo>();

		if (!hasSites()) {
			return ret;
		}

		List<Sobject> sitesResults = Database.query('Select Name, Subdomain, UrlPathPrefix from Site Where Status = \'Active\'');

		for (Sobject current : sitesResults) {
			ret.add(new SurveySiteInfo((String)current.get('Name'), (String)current.get('UrlPathPrefix'), (String)current.get('Subdomain')));
		}

		return ret;

	}

	public class SurveySiteInfo {
		public String name { get; set; }
		public String prefix { get; set; }
		public String subdomain {get; set; }

		public SurveySiteInfo(String name, String prefix, String subdomain) {
			this.name = name;
			this.prefix = prefix;
			this.subdomain = subdomain;
		}
	}
}