/********************************************************************************************************************
 * @author Praveen
 * @date 09/17/2022
 *
 * @group Merchant Services
 *
 * @description Helper class for equipement request controller.
 * 
 *
 **************************************************************************************************************************************/

public with sharing class CDdMxEquipmentRequestHelper {
    public static final Set<String> validRequestTypeFamily = new Set<String>{'New','Protocol Upgrade'}; 
     /**
     * @description Method will return the order request types for return screen. 
     * @param String
     * @param set<string>
     * @return set<string>
     */
    public static Set<String> getReturnOrderRequests(String actId,  Set<String> validRequestTypesForReturns) {
        set<String> oldRequestTypes = new Set<String>();
			for (Mx_Order__c mxOrder : [
				SELECT id, Mx_Order_Request__r.Request_Type__c
				FROM Mx_Order__c
				WHERE Account__c = :actId AND Mx_Order_Request__r.Request_Type_Family__c IN: validRequestTypeFamily
				ORDER BY createddate DESC
				LIMIT 1
			]) {
				oldRequestTypes.add(mxOrder.Mx_Order_Request__r.Request_Type__c);
			}
			if (oldRequestTypes.size() == 0) {
				for (case cs : [
					SELECT id, Request_Type__c
					FROM case
					WHERE AccountId = :actId AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS AND Request_Type__c IN: validRequestTypesForReturns
					ORDER BY createddate DESC
					LIMIT 1
				]) {
					oldRequestTypes.add(cs.Request_Type__c);
				}
			}
            return oldRequestTypes;
    }
}