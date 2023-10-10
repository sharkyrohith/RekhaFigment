/**
 * 
 * @author: Tia Xuan
 * @date: 2019-05
 * @description class for LDdDispatchCalloutCmp
 * 
 */
public class CDdDispatchCalloutCtrl {
    
    /**
     * @description make a call out to the dispatch service.
     */
    @AuraEnabled
	public static void makeDeliveryCallout(String caseId) {
		Dispatch_Settings__c settings = Dispatch_Settings__c.getInstance();
        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
		Case[] pCse = [select Id, DeliveryNo__c, ContactPhone, ContactEmail, Platform__c, DeliveryUUID__c, Customer_Type__c, ChatKey__c, RecordTypeId, AccountId, Origin, Issue_Type__c
			from Case
			where Id =: caseId]; 

		Integer responseFieldLength = Schema.SObjectType.Case.fields.DispatchRQResponse__c.getLength();

		if(pCse.size() == 1) {
			Case c = pCse[0];

            // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
			if(String.isNotBlank(c.DeliveryUUID__c)
				|| ((c.Customer_Type__c == CDdSupportConstants.CUSTOMER_TYPE_DASHER
					|| c.Customer_Type__c ==CDdSupportConstants.CUSTOMER_TYPE_CONSUMER)
                    && (String.isNotBlank(c.ContactEmail) 
					|| String.isNotBlank(c.ContactPhone)))){
                
				VDispatchDeliveryCalloutQueueable q = new VDispatchDeliveryCalloutQueueable(new List<Case> { c }, false, 
                                                                                            (c.RecordTypeId == settings.Case_API_Record_Type_ID__c
                                                                                                || (c.Origin != 'Chat' && c.Origin != 'Web' && c.Origin != 'Email')), 
                                                                                            (c.RecordTypeId == settings.Case_API_Record_Type_ID__c
                                                                                                || (c.Origin != 'Chat' && c.Origin != 'Web' && c.Origin != 'Email')));
				try {
					q.execute(null);

					c = [select Id, DispatchCalloutException__c, DispatchRQResponse__c from Case where Id = :c.Id];

					if(c.DispatchCalloutException__c != null && !Label.DispatchBlankSalesforceAudienceInfo.contains(c.DispatchCalloutException__c)) {
						if(c.DispatchRQResponse__c != null && c.DispatchRQResponse__c.contains('Not found')) {
							throw new AuraHandledException(Label.vDispatch404);
						} else {
							throw new AuraHandledException(c.DispatchCalloutException__c);
						}
					} 
                    
					if(Test.isRunningTest()) {
						throw new VTestUtil.TestException('Test');
					}
				} catch(Exception e) {
	        		c.DispatchRQStatus__c = 'Failure';
	        		c.DispatchCalloutException__c = e.getMessage();

	        		VDispatchRecordService.clearFieldsOnError(c);
	        		update c;

	        		throw e;
				}
			} else {
				 throw new AuraHandledException(Label.vMissingDeliveryNo);
			}
		} else {
			throw new AuraHandledException(Label.vMissingCaseID);
		}
	}

}