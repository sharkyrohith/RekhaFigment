public class CDdNimdaSyncPollingController {

	private static final String TOPIC_NAME = 'NimdaSync';	
    public String filter {get; private set;}
    public String channel {get; private set;}
    public Integer replayFrom {get;set;}
    public String orgDomainURL {get; private set;}


	public CDdNimdaSyncPollingController() {
		Id recordId = ApexPages.currentPage().getParameters().get('Id');
        this.filter = (String.isNotBlank(recordId) ? '?' + 'id=' + recordId : '');
        this.channel = '/topic/' + TOPIC_NAME;
        this.replayFrom = -1;
        this.orgDomainURL = URL.getSalesforceBaseUrl().toExternalForm();
    }

    @AuraEnabled
    public static String getNimdaSyncPollingPageURL() {
        return (URL.getSalesforceBaseUrl().toExternalForm() + '/apex/PDdNimdaSyncPolling');
    }
}