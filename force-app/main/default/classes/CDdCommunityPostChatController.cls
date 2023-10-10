/**
 * 
 * @author: Tia Xuan
 * @date: 2020-07
 * @description Community post chat to get to survey
 * 
 */
public class CDdCommunityPostChatController {
    public QueryRecord caseObj { get; set; }
    public String surveyURL { get; set; }
    public String fromURL { get; set; }
    public String lang { get; set; }

    public CDdCommunityPostChatController() {
        String chatKey = ApexPages.currentPage().getParameters().get('chatKey');
        this.fromURL = ApexPages.currentPage().getParameters().get('from');
        this.lang = ApexPages.currentPage().getParameters().get('language');
        this.caseObj = getCaseInfo(chatKey);
    }
                            
    public QueryRecord getCaseInfo(String chatKey){
        String restURL = 'callout:SalesforceNamedCred/services/data/v48.0/query/?q=';
        restURL += 'select+CaseId,+Case.OwnerId,+Case.CaseOriginFormatted__c,+Case.CreatedDate+,+Case.ContactId+,+Case.SuppliedEmail+from+LiveChatTranscript+where+ChatKey=\'';

        restURL += EncodingUtil.urlEncode(chatKey, 'UTF-8');
        restURL += '\'';

        Http http = new Http();   
        HttpRequest req = new HttpRequest();  
        req.setMethod('GET');   
        req.setHeader('Content-Type', 'application/json');   
        req.setEndpoint(restURL); 
        req.setTimeout(60000);
        HttpResponse resp = http.send(req);  
        if (resp.getStatusCode() == 200) {
            String body = resp.getBody();
            body = body.replaceAll('"Case"', '"CaseObj"');
            body = body.replaceAll('"CaseOriginFormatted__c"', '"Origin"');
            QueryResp respObj = (QueryResp) JSON.deserialize(body, QueryResp.class);
            if (respObj.records.size() > 0){
                return respObj.records[0];
            }
        }
        return null;  
    }

    public PageReference goToSurvey(){
        String contactId = String.isNotBlank(this.caseObj.CaseObj.ContactId) ? this.caseObj.CaseObj.ContactId : '';
        String email = String.isNotBlank(this.caseObj.CaseObj.SuppliedEmail) ? this.caseObj.CaseObj.SuppliedEmail : '';
        this.surveyURL =  System.Label.DdCommunity_DelightedSupportURL 
                            + '?CaseId=' + this.caseObj.caseId
                            + '&UserId=' + this.caseObj.CaseObj.OwnerId
                            + '&CaseCreatedDate=' + this.caseObj.CaseObj.CreatedDate
                            + '&CaseOriginFormatted=' + this.caseObj.CaseObj.Origin
                            + '&SalesforceContactID=' + contactId
                            + '&Email=' + email
                            + '&SurveyOpened=' + DateTime.now();
        Pagereference pr = new Pagereference(this.surveyURL);
        pr.setRedirect(true);
        return pr;
    }

    public class QueryResp{
        public Integer totalSize {get; set;}
        public Boolean done {get; set;}
        public List<QueryRecord> records {get; set;}
    }

    public class QueryRecord{
        public String caseId {get; set;}
        public QueryRelationshipRecord CaseObj {get; set;}        
    }

    public class QueryRelationshipRecord{
        public String OwnerId {get; set;}
        public DateTime CreatedDate {get; set;}
        public String Origin {get; set;}
        public String ContactId {get; set;}
        public String SuppliedEmail {get; set;}
    }  
}