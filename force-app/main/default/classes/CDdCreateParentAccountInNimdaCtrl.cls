public class CDdCreateParentAccountInNimdaCtrl {

    public Id acctId {get; set;}
    public Account acct {get; set;}
    public List<Account> acctsToUpdate {get; set;}
    public String showError {get; set;}
    public String errorMsg {get; set;}
    private vCS__c apiSettings = vCS__c.getInstance();
    public CDdRESTConnectorSvc connector {get; set;}
    
    public CDdCreateParentAccountInNimdaCtrl(ApexPages.StandardController controller) {
        PageReference pg = ApexPages.currentPage();
        acctId = pg.getParameters().get('id');
        if (acctId != null) {
            acct = (Account) [
                                SELECT 
                                    Id, Name, Business_ID__c, Description 
                                FROM 
                                    Account 
                                WHERE 
                                    Id = :acctId
                            ];
        }
        acctsToUpdate = new List<Account>();
        connector = new CDdRESTConnectorSvc();
    }

    public PageReference createBusiness() {
        if (acct != null) {
            if (acct.Business_ID__c != null) {
                return backToAccount('ERROR: Business already exists!');
            }

            CDdRestJSONObj.DoorstepBusinessRequest businessReq = new CDdRestJSONObj.DoorstepBusinessRequest();
            businessReq.name = acct.Name;
            businessReq.description = String.isBlank(acct.Description) ? 'Sent from SFDC' : acct.Description;
            
            //Need to use JSON.serialize(reqObj, true) to remove nulls before sending request
            CDdRestJSONObj.RestAPIResponse businessRes = connector.postDoorstep(JSON.serialize(businessReq, true), '/v1/businesses');
            CDdRestJSONObj.DoorstepBusinessResponse business = (CDdRestJSONObj.DoorstepBusinessResponse) JSON.deserialize(businessRes.body, CDdRestJSONObj.DoorstepBusinessResponse.class);
            if (business.id == null) {
                return backToAccount('ERROR: No business id assigned!');            
            } 
            acct.Business_Id__c = business.id;
            acctsToUpdate.add(acct);
            return backToAccount();
        }
        else {
            return backToAccount('ERROR: Account passed is not valid! Make sure you pass a valid Account id!');
        }
    }

    public PageReference backToAccount() {
        return backToAccount(null);
    }

    public PageReference backToAccount(String error) {
        if (String.isNotBlank(error) && error != null) {
            errorMsg = error;
            showError = '';
            return null;
        } else {
            if (!acctsToUpdate.isEmpty()) {
            	upsert acctsToUpdate;
            }
            
            PageReference pr = new PageReference('/' + String.valueOf(acctId));
        	return pr;
        }
    }    
}