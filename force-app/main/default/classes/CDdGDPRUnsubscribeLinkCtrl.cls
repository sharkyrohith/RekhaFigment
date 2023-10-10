public class CDdGDPRUnsubscribeLinkCtrl {

    public String strEmail {get;set;}
    public String strPersona {get;set;}
    public String strCaseId {get;set;}
    public String strEmailType {get;set;}
    public List<String> htmlTypes {get {
        if (strEmailType == 'html'){
            return new List<String>{'html'};
        } else {
            return new List<String>();
        }
    }}
    public List<String> textTypes {get {
        if (strEmailType == 'text'){
            return new List<String>{'text'};
        } else {
            return new List<String>();
        }
    }}
    public String subLink { get{
        String persona = this.strPersona;
        String language = CDdGDPRConstants.DEFAULT_LANGUAGE;
        if (String.isNotBlank(this.strCaseId)) {
            Map<Id, String> personaMap = CDdGDPREmailHelper.getPersonaLanguageFromCase(new List<Id>{this.strCaseId});
            if (personaMap.containsKey(this.strCaseId)){
                String perLang = personaMap.get(this.strCaseId);
                List<String> perLangList = perLang.split(CDdGDPRConstants.SEPARATOR);
                persona = perLangList[0];
                if (perLangList.size() > 1){
                    language = perLangList[1];
                }
            }
        }
        return CDdGDPREmailHelper.getEncryptedSubscriptionLink(strEmail, persona, language);
    }}
}