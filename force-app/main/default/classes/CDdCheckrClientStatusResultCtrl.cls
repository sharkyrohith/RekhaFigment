public class CDdCheckrClientStatusResultCtrl {
    public String name {get; set;}
    public String mvStatus {get; set;}
    public String bgStatus {get; set;}
    public String checkrId {get; set;}
    public String email {get; set;}
    public boolean hasError {get; set;}
    public String errorMsg {get; set;}

	public String mvStyle {get; set;}
    public String bgStyle {get; set;}
	public String mvConsider {get; set;}
    public String bgConsider {get; set;}    
    public String cardStyle {get; set;}
    public String errorStyle {get; set;}
    
    public String mvTooltip {get; set;}
    public String bgTooltip {get; set;}
    
    public CDdRestConnectorSvc connector;
    
    public CDdCheckrClientStatusResultCtrl() {
        email = ApexPages.currentPage().getParameters().get('email');
        hasError = false;
        connector = new CDdRestConnectorSvc();
        cardStyle = 'block';
        errorStyle = 'none';
        mvConsider = '';
        bgConsider = '';
    }
    
    public void getCheckrStatus() {
        try{
            CDdRestJSONObj.RestAPIResponse response = connector.getDoorstep('/v1/dasher_applicants/' + email, '/background_check_status/');
            CDdRestJSONObj.DoorstepDasherCheckrStatusResponse checkrStatus = (CDdRestJSONObj.DoorstepDasherCheckrStatusResponse) JSON.deserialize(response.body, CDdRestJSONObj.DoorstepDasherCheckrStatusResponse.class);        
            if (!String.isBlank(checkrStatus.detail)) {
                //there's an error. handle it
                hasError = true;
                errorMsg = checkrStatus.detail;
            }
            this.name = !String.isBlank(checkrStatus.name) ? checkrStatus.name : 'Dasher Applicant';
            this.mvStatus = !String.isBlank(checkrStatus.mv_report_results) ? checkrStatus.mv_report_results : 'N/A';
            this.bgStatus = !String.isBlank(checkrStatus.background_check_results) ? checkrStatus.background_check_results : 'N/A';
            
            stylePage();
        } catch( Exception e ) {
            hasError = true;
            errorMsg = 'Uh-oh! Looks like you weren\'t able to connect to the server! Please try again later.';
        }
        
    }
    
    public void stylePage() {
        if (hasError) {
            cardStyle = 'none';
        	errorStyle = 'block';
        }
        if (mvStatus.equalsIgnoreCase('consider')) {
            mvConsider = 'background-color: #dbbf08;';
        }
        if (bgStatus.equalsIgnoreCase('consider')) {
            bgConsider = 'background-color: #dbbf08;';
        }
        mvStyle = getButtonStyle(mvStatus);
        bgStyle = getButtonStyle(bgStatus);
        
        mvTooltip = getTooltipText(mvStatus);
        bgTooltip = getTooltipText(bgStatus);
    }
    
    public String getButtonStyle(String state) {
        if (state == null) {
            return 'slds-button_inverse';
        } else if (state.equalsIgnoreCase('clear')) {
            return 'slds-button_success';
        } else if (state.equalsIgnoreCase('suspended')) {
            return 'slds-button_destructive';
        } else if (state.equalsIgnoreCase('consider')) {
            return 'slds-button_brand';
        } else if (state.equalsIgnoreCase('pending')) {
            return 'slds-button_brand';
        } else {
            return 'slds-button_neutral';
        }
    }
    
    public String getTooltipText(String state) {
        if (state == null) {
            return 'Sorry! Didn\'t see it in our servers!';
        } else if (state.equalsIgnoreCase('clear')) {
            return 'Good to go!';
        } else if (state.equalsIgnoreCase('suspended')) {
            return 'One or more pieces of information are missing or incorrect';
        } else if (state.equalsIgnoreCase('consider')) {
            return 'The report is complete and contains some sort of adverse information to evaluate (criminal records, traffic infractions, etc.)';
        } else {
			return '';
        }
    }
    
    public PageReference goBack() {
        return Page.PDdCheckrClientStatus;
    }
}