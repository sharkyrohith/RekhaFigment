/********************************************************************************************************************
 * @author Praveen
 * @date 07/14/2022
 *
 * @group Merchant Services
 *
 * @description Equipment request controller to raise support cases for tablet cases.
 *
 **************************************************************************************************************************************/

public with sharing class CDdMxEquipmentRequestController {
	/**
	 * Define class variables here
	 */
	public static final String ORDER_PROTOCOL = CDdMxSxConstants.getEquipmentRequestOrderProtocol();
	public static final String ACT_RECORD_TYPES = CDdMxSxConstants.getEquipmentRequestAccountRecordType();
	public static final String REQUEST_TYPE_MAP_RETURN_PRODUCTS = CDdMxSxConstants.getEquipmentRequestReturnProductMap();
	public static final String REQUEST_TYPE_MAP_PROTOCOL_UPGRADE = CDdMxSxConstants.getEquipmentRequestProtocolUpgradeMap();
	public static final String TYPE_OF_ORDER_NEW = CDdMxSxConstants.TYPE_OF_MX_ORDER_NEW;
	public static final String TYPE_OF_ORDER_RETURN = CDdMxSxConstants.TYPE_OF_MX_ORDER_RETURN;
    public static final String TYPE_OF_ORDER_REPLACEMENT = CDdMxSxConstants.TYPE_OF_MX_ORDER_REPLACEMENT;
	public static final String OPP_OBJECT = 'Opportunity';
	public static final String CONTACT_OBJECT = 'Contact';
	public static final String TABLET_IMEI = 'tablet';
	public static final String PRINTER_IMEI = 'printer';
	public static final String TABLET_IMEI_API = 'Tablet_Serial_Number__c';
	public static final String PRINTER_IMEI_API = 'Printer_IMEI__c';
	public static final String CONTACT_ICON = 'standard:contact';
	public static final String IMEI_ICON = 'standard:macros';
	public static final String REQUEST_TYPE_RETURNLABEL = 'Return Label Only';
	public static final String PTOCOL_UPDAGRE = 'Protocol Upgrade';
	public static final String DEFAULT_ORDER_PROTOCOL = 'POS and Tablet (DoorDash Owns)';
	public static final String DEFAULT_ACT_RECORD_TYPE = 'Marketplace';
	public static final String CASE_IMEIObject = 'Case';
	public static final String ORDER_IMEIObject = 'Order';
	public static final String RETURN_LABEL_REQUEST_TYPE = 'Email to Merchant (Return Label Only)';
	public static final String PRINTER_PERMISSION_SET_NAME = 'Bypass_Printer_Block';
	public static final set<String> ACCOUNT_DECK_RANKS = new Set<String>{ 'Ace of Spades', 'King of Spades', 'Ace', 'King' };
	public static final String DISABLE_CASE_TRIGGER_UI_FLOW = 'Disable_Case_Trigger_UI_Flow';
	public static final Set<String> VALID_REQUEST_TYPE_FAMILY_FOR_NEW_ORDER = new Set<String>{'New','Protocol Upgrade'};
	public static final String LEMONADE_CASE_ORIGIN_UI = CDdMxSxConstants.CASE_ORIGIN_UI_LEMONADE; 
	/**
	 * @description create case from controller
	 * @param void payload
	 */

	@auraEnabled
	public static List<String> CreateCases(string payload) {
		try {
			List<String> caseIds = new List<String>();
			List<Case> css = new List<Case>();
			CDdMxEquipmentRequestModel payloadObject = (CDdMxEquipmentRequestModel) JSON.deserialize(payload, CDdMxEquipmentRequestModel.class);
			Boolean isFirstRequest = isFirstRequest(payloadObject.AccountId);
            Account act = getAccount(payloadObject.AccountId);
			if (string.isNotBlank(payloadObject.requestType) && !RETURN_LABEL_REQUEST_TYPE.equals(payloadObject.requestType)) {
				css.add(CreateCase(payloadObject, false, isFirstRequest, act));
			}
			if (payloadObject.returnReplaceComponent == 'Yes' ) {
				css.add(CreateCase(payloadObject, true, isFirstRequest, act));
			}

			if (CDdMxSxConstants.isDisabled(DISABLE_CASE_TRIGGER_UI_FLOW)) {
				CDdTriggerConstantsUtil.skipTriggerExecutionSet.add(CDdTriggerConstantsUtil.skipCaseTrigger);
			}
            if(css.isempty()){
                throw AuraException(' No cases created. Please select different request type or select return replacement request');
            }
			insert css;
			List<case> newCases = [select id,caseNumber from case where Id IN:css ];
			for(case newCase : newCases ){
				caseIds.add(newCase.casenumber);
			}
			new CDdMxOrderEventHandler(CDdMxOrderEventEnum.GENERATE_MX_ORDER, css).execute();
			Map<Id, List<String>> productToOrderIdMap = new Map<Id, List<String>>();
			List<Mx_Order__c> newMxOrders = [SELECT id, OriginalMxorder__c, Type_Of_Mx_Order__c, Mx_Order_Request__r.Request_Type__c FROM Mx_Order__c WHERE case__c IN :css];
			for (Mx_Order__c mxOrder : newMxOrders) {
				mxOrder.Internal_Deployment__c = payloadObject.internalDeployment == 'Yes' ? true : false;
				mxOrder.Store_Order_Protocol__c = payloadObject.mintOrderProtocol;
				if (mxOrder.Type_Of_Mx_Order__c == TYPE_OF_ORDER_RETURN) {
					//mxOrder.Mx_Order_Request__r.Request_Type__c == RETURN_LABEL_REQUEST_TYPE
					mxOrder.Type_Of_Mx_Order__c = TYPE_OF_ORDER_RETURN;
					if (payloadObject.IMEIObject == ORDER_IMEIObject && string.isNotBlank(payloadObject.originalTabletCaseId)) {
						mxOrder.OriginalMxorder__c = payloadObject.originalTabletCaseId;
					}
					productToOrderIdMap.put(mxOrder.Id, payloadObject.returnProducts);
				} else {
					productToOrderIdMap.put(mxOrder.Id, payloadObject.newProducts);
				}
			}
			update newMxOrders;
			new CDdMxOrderItemHandler(newMxOrders, productToOrderIdMap, payloadObject.tabletImei, payloadObject.printerImei).insertOrderItems();
		return caseIds;
		} catch (exception e) {
			throw new AuraHandledException('Error while creating case' + e.getMessage() + ' line: ' + e.getLineNumber());
		}
	}

	/**
	 * @description Printer request will be blocked for users because vendor is out of printers.
	 * @param  payload recevies the payload from UI for validation.
	 * @return case
	 */
	@auraEnabled
	public static Boolean validatePrinterRequest(string payload) {
		CDdMxEquipmentRequestModel payloadObject = (CDdMxEquipmentRequestModel) JSON.deserialize(payload, CDdMxEquipmentRequestModel.class);
		Boolean allowPrinterRequest = false;
		// printer request validation
		if (String.isNotBlank(payloadObject.requestType) && CDdMxSxConstants.CASE_REQUEST_TYPES_FOR_INCLUSION_OF_PRINTER.contains(payloadObject.requestType)) {		
		// Opp validation
            if(String.isNotBlank(payloadObject.OppId)){
                allowPrinterRequest = (CDdMxSxCaseHelper.isMxEligibleForPrinter(new set<Id>{payloadObject.OppId})).get(payloadObject.OppId);            
            }else if(CDdMxSxCaseHelper.byPassSendPrinterValidationsForUser()){
                allowPrinterRequest = true;
            }else {
                Account acc = [select id,Top_Mx__c,Deck_Rank__c from Account where Id  =:payloadObject.AccountId ];
                allowPrinterRequest = CDdMxSxCaseHelper.isTopMxAccountToSendPrinter(acc);
            }
        }else{
           allowPrinterRequest = true; 
        }        
		return allowPrinterRequest;
	}

	public static Boolean isFirstRequest(String accountId){
		return [SELECT COUNT() FROM case WHERE AccountId = :accountId AND recordtypeId = :CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS] == 0 ? true : false;

	}
	/**
	 *  @description CreateCase method will create the case instance and copy the payload to object to instance.
	 * @param  CDdMxEquipmentRequestModel pass payload from UI.
	 * @return case
	 */
	public static case CreateCase(CDdMxEquipmentRequestModel payload, Boolean isReturnOrder, Boolean isFirstRequest ,Account act) {
		case cs = new case();
		String RequestType = String.isNotBlank(payload.requestType) ? payload.requestType : RETURN_LABEL_REQUEST_TYPE;
		cs.accountid = payload.AccountId;
		cs.ContactId = payload.contactId;
		cs.Merchant_has_Wifi__c = payload.merchanthasWifi;
		if(String.isNotBlank(payload.OppId)){
		cs.Opportunity_Name__c = payload.OppId;
		}
		cs.RecordTypeId = CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS;
		cs.Request_Type__c = RequestType;
		cs.Return_Replaced_Components__c = payload.returnReplaceComponent;
		cs.Return_Shipping_Address_City__c = payload.City;
		cs.Return_Shipping_Address_State__c = payload.State;
		cs.Shipping_Address_Country__c = payload.Country;
		cs.Return_Shipping_Address_Zip__c = payload.PostalCode;
		cs.Return_Shipping_Address_Street__c = payload.Addressline1;
		cs.Return_Shipping_Address_Suite_Apt_etc__c = payload.Addressline2;
		cs.Shipping_Type__c = payload.shippingType;
		cs.Defective_Printer_IMEI__c = payload.printerImei;
		cs.Defective_Tablet_IMEI__c = payload.tabletImei;
		cs.Replacement_Reason_Other_2__c = payload.reasonForReplOther;
		if(String.isNotBlank(payload.replacementReason)){
            cs.Reason_for_Replacement__c = payload.replacementReason;
        }
		String caseOriginFirst = isFirstRequest
			? new List<String>(CDdMxSxConstants.getCaseOriginToRequestMap().get(RequestType).keySet())[0]
			: CDdMxSxConstants.getCaseOriginToRequestMap().get(RequestType).values()[0];
		cs.Origin = payload.isLemonadeAccount ? LEMONADE_CASE_ORIGIN_UI: caseOriginFirst;
        if(CDdMxSxConstants.NEW_MERCHANT_REQUEST_TYPES.contains(RequestType) && isFirstRequest && !CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(act.RecordTypeId)){
          cs.Include_Marketing_Kit__c = true;  
        }
		if (isReturnOrder) {			
			cs.Request_Type__c = RETURN_LABEL_REQUEST_TYPE;
			cs.Type_Of_Mx_Order__c = TYPE_OF_ORDER_RETURN;            
		} else if(!isFirstRequest){
			cs.Type_Of_Mx_Order__c = TYPE_OF_ORDER_REPLACEMENT;
        } else{
            cs.Type_Of_Mx_Order__c = TYPE_OF_ORDER_NEW;
        }
		return cs;
	}
	/**
	 *  @description getAccountDetails while loading lwc page. Accepts either Account id or opp Id.
	 * @param  String recordId - Collection of Opportunity Ids
	 * @return CDdMxAccountModel
	 */

	@AuraEnabled(Cacheable=true)
	public static CDdMxAccountModel getAccountDetails(String recordId) {
        try {
            List<string> actRecordType = String.isNotBlank(ACT_RECORD_TYPES) ? ACT_RECORD_TYPES.split(',') : new List<string>{ DEFAULT_ACT_RECORD_TYPE };
            string objectName = findObjectNameFromRecordIdPrefix(recordId);
            string opportunityId = '';
            if (!objectName.equalsIgnoreCase('account')) {
                Opportunity opp = [SELECT AccountId, platform__c , Order_Protocol__c, Account.RecordType.Name FROM Opportunity WHERE Id = :recordId];
                opportunityId = recordId;
                recordId = opp.AccountId;
                if (!actRecordType.contains(opp.Account.RecordType.Name)) {
                    throw new AuraHandledException('Opportunity should be originated from one of the account record types ' + actRecordType);
                }
            }
            Account act = [
                SELECT id, Name, BillingStreet,Restaurant_Id__c,Lemonade_Record_ID__c, Language__c,RecordType.Name, 
                address2__c, Deck_Rank__c, Top_Mx__c, BillingCountryCode, BillingState, BillingCity, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id = :recordId
            ];
            if (!actRecordType.contains(act.RecordType.Name)) {
                throw new AuraHandledException('Account should be originated from one of the account record types ' + actRecordType);
            }
			Boolean isFirstRequest =isFirstRequest(recordId);
            CDdMxAccountModel actModel = new CDdMxAccountModel();
            actModel.AccountId = act.Id;
            actModel.Name = act.Name;
            actModel.opportunityId = opportunityId;
            actModel.Addressline1 = act.BillingStreet;
            actModel.Addressline2 = act.address2__c;
            actModel.City = act.BillingCity;
            actModel.State = act.BillingState;
            actModel.Country = act.BillingCountry;
            actModel.PostalCode = act.BillingPostalCode;
            actModel.BillingCountryCode = act.BillingCountryCode;
            actModel.isFirstRequest = isFirstRequest;
            actModel.storeId = act.Restaurant_Id__c;
            actModel.isLemonadeAccount = String.isNotBlank(act.Lemonade_Record_ID__c);
            actModel.language = String.isNotBlank(act.Language__c)?act.Language__c:'English';
            String actString = JSON.serialize(actModel);
            CDdMxAccountModel actObj = new CDdMxAccountModel(actString);
            return  actObj;      
        
        } catch (Exception e) {
            throw new AuraHandledException('Error while getting account details' + e.getMessage() + ' line: ' + e.getLineNumber());
        }
	}
	/**
	 * @description getOrderRequests and order request products. Map extra lines bases on the system labels return type and order protocol.
	 * @param
	 * @return List<CDdMxEquipmentOrderRequestModel>
	 */
	@AuraEnabled(Cacheable=true)
	public static List<CDdMxEquipmentOrderRequestModel> getOrderRequests(String actId) {
		try {
			Set<String> validRequestTypesForReturnEligible = new Set<String>();
            Account act = getAccount(actId);
			List<Mx_Order_Request__c> mxOrderRequests= [
			SELECT Id,Country_Code__c,Display_in_Equipment_Request_UI__c,Is_Active__c,Is_Routing_Enabled__c,Request_Type__c,Request_Type_Family__c,
			(
			SELECT Mx_Product__c, Mx_Order_Request__c, SKU_Social_Mobile__c, Id, Mx_Product__r.Family__c, Mx_Product__r.Language__c, Mx_Product__r.Is_McDonald_Kit__c, Mx_Product__r.Name
			FROM Mx_Order_Request_Products__r
			)
			FROM Mx_Order_Request__c
			WHERE Country_Code__c = :act.BillingCountryCode];
			for (Mx_Order_Request__c mxRequest : mxOrderRequests){ 
				if(VALID_REQUEST_TYPE_FAMILY_FOR_NEW_ORDER.contains(mxRequest.Request_Type_Family__c)){
					validRequestTypesForReturnEligible.add(mxRequest.Request_Type__c);
				}
			}
			Set<String> oldRequestTypes = CDdMxEquipmentRequestHelper.getReturnOrderRequests(actId,validRequestTypesForReturnEligible);
			List<CDdMxEquipmentOrderRequestModel> mxOrderRequestList = new List<CDdMxEquipmentOrderRequestModel>();
			for (Mx_Order_Request__c mxRequest : mxOrderRequests) {
				if (oldRequestTypes.contains(mxRequest.Request_Type__c)) {
					CDdMxEquipmentOrderRequestModel mxOrderRequestsReturn = new CDdMxEquipmentOrderRequestModel(REQUEST_TYPE_RETURNLABEL, mxRequest.Id, mxRequest.Mx_Order_Request_Products__r, act);
					mxOrderRequestList.add(mxOrderRequestsReturn);
				}
			    if (mxRequest.Display_in_Equipment_Request_UI__c){
                    CDdMxEquipmentOrderRequestModel newMxOrderRequestProducts = new CDdMxEquipmentOrderRequestModel(mxRequest.Request_Type__c, mxRequest.Id, mxRequest.Mx_Order_Request_Products__r, act);
					mxOrderRequestList.add(newMxOrderRequestProducts);
                }
			}

			return mxOrderRequestList;
		} catch (exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @description search method exposed to controller for searching opp, contacts and IMEI numbers.
	 * @param String searchTerm, String recordId, String searchObject, String opportunityId
	 * @return List<CDdMxEquipmentLookupSearchModel>
	 */
	@AuraEnabled
	public static List<CDdMxEquipmentLookupSearchModel> search(String searchTerm, String recordId, String searchObject, String opportunityId) {
		try {
			List<CDdMxEquipmentLookupSearchModel> results = new List<CDdMxEquipmentLookupSearchModel>();
			if (searchObject.equalsIgnoreCase(CONTACT_OBJECT)) {
				results = getContacts(searchTerm, recordId, searchObject, opportunityId);
			} else if (searchObject.equalsIgnoreCase(OPP_OBJECT)) {
				results = getOpportunities(searchTerm, recordId);
			} else {
				results = getIMEInumbers(searchTerm, recordId, searchObject);
			}
			return results;
		} catch (exception e) {
			throw new AuraHandledException('Exception while doing search: ' + e.getMessage() + 'line ' + e.getLineNumber());
		}
	}

	/**
	 *@description getContacts method for fetching contacts based on the search term.
	 *@param String searchTerm,
	 *@param String  recordId,
	 *@param String  searchObject,
	 *@param String opportunityId
	 *@return List<CDdMxEquipmentLookupSearchModel>
	 */
    public static List<CDdMxEquipmentLookupSearchModel> getContacts(String searchTerm, String recordId, String searchObject, String opportunityId) {
        List<CDdMxEquipmentLookupSearchModel> results = new List<CDdMxEquipmentLookupSearchModel>();
        List<AccountContactRelation> contacts = new List<AccountContactRelation>();
        Account act = [select id,Ultimate_Parent_Account__c from Account where Id =:recordId];
        String ultimateParent = act.Ultimate_Parent_Account__c;
        String searchInput ='\'%' + searchTerm  + '%\'';
        String Soql = 'SELECT contact.id,contact.Firstname,contact.Lastname, contact.Name, contact.Phone, contact.Email FROM AccountContactRelation';
        if(String.isNotBlank(searchTerm) && String.isNotBlank(act.Ultimate_Parent_Account__c)){
            Soql +=' Where Account.Ultimate_Parent_Account__c = :ultimateParent and contact.name Like ' +searchInput+ ' limit 20';	
        }else {
            Soql += ' Where AccountId =:recordId';
        }
        contacts = (List<AccountContactRelation>)Database.query(Soql);
        if (string.isNotBlank(opportunityId)) {
            // querying contact to make contact record default.			
            Contact[] con = [SELECT id, FirstName, LastName, Name, Phone, Email 
                             FROM contact 
                             WHERE Id =:[select Decision_Maker__c from Opportunity where Id =:opportunityId].Decision_Maker__c];
            if (con.size() > 0){
                String subtitle = con[0].Phone + ' • ' + con[0].Email;
                Boolean requiredContactFieldisnull = con[0].Phone == null || con[0].Email == null || con[0].FirstName == null || con[0].Lastname == null;
                results.add(new CDdMxEquipmentLookupSearchModel(con[0].Id, CONTACT_OBJECT, CONTACT_ICON, con[0].Firstname + ' ' + con[0].LastName, subtitle, '', requiredContactFieldisnull));
            }
        }
        for (AccountContactRelation con : contacts) {
            String subtitle = con.contact.Phone + ' • ' + con.contact.Email;
            Boolean requiredContactFieldisnull = con.contact.Phone == null || con.contact.Email == null || con.contact.Firstname == null || con.contact.Lastname == null;
            results.add(
                new CDdMxEquipmentLookupSearchModel(con.contact.Id, CONTACT_OBJECT, CONTACT_ICON, con.contact.Firstname + ' ' + con.contact.LastName, subtitle, '', requiredContactFieldisnull));
        }
        return results;
    }
	/**
	*@description getOpportunities method for fetching opportunities based on the search term.
	*@param String searchTerm Opportunity name search ** Opportunity Name **
	*@param String recordId Opportunity accountId for opportunity search
	*@param String opportunityId If the user is creating case from opportunity. Opportunity Id will be defaulted
	*@return List<CDdMxEquipmentLookupSearchModel>
	*/
	public static List<CDdMxEquipmentLookupSearchModel> getOpportunities(String searchTerm, String accountId) {
		try {
			List<CDdMxEquipmentLookupSearchModel> results = new List<CDdMxEquipmentLookupSearchModel>();
			Opportunity[] opps = new List<Opportunity>();
			List<String> orderProtocols = String.isNotBlank(ORDER_PROTOCOL) ? ORDER_PROTOCOL.split(',') : new List<String>{ DEFAULT_ORDER_PROTOCOL };
			if(String.isBlank(searchTerm)){
				opps = OpportunitiesSelector.newInstance().getOpportunitiesByAccountIds(new Set<Id>{accountId});
				getOpportunityResultsModel(opps, results, orderProtocols);
			} else{
				List<List<sObject>> opportunitySearchResults = OpportunitiesSelector.newInstance().searchOpportunitiesBysearchTermAndAccountIds(searchTerm, new Set<Id>{accountId});
				opps = (Opportunity[])opportunitySearchResults[0];
				getOpportunityResultsModel(opps, results, orderProtocols);
			}
			return results;
		} catch (Exception ex) {
			throw AuraException('Message '+ex.getMessage() +' '+ex.getLineNumber());
		}
	}
	/**
	*@description getOpportunities method for fetching opportunities based on the search term.
	*@param List<Opportunity> List of opportunities from results search
	*@param List<CDdMxEquipmentLookupSearchModel> opportunityResults to return.
	*@param List<string> orderProtocols list
	*@return List<CDdMxEquipmentLookupSearchModel>
	*/
	public static List<CDdMxEquipmentLookupSearchModel> getOpportunityResultsModel(List<Opportunity> opportunities, List<CDdMxEquipmentLookupSearchModel> opportunityResults, List<string> orderProtocols){
		for (Opportunity opp : opportunities) {
			if(orderProtocols.contains(opp.Order_Protocol__c)){
				String subtitle = opp.Order_Protocol__c + ' • ' + opp.stageName + ' • ' + opp.CloseDate + ' • ' + opp.RecordType.Name;
				opportunityResults.add(new CDdMxEquipmentLookupSearchModel(opp.Id, OPP_OBJECT, CONTACT_ICON, opp.Name, subtitle, '', false));
			}
		}
		return opportunityResults;
	}
	/**
	 *@description getIMEInumbers method for fetching tablet and printer IMEI numbers based on the search term from previous cases records.
	 *@param String searchTerm,
	 *@param String  recordId,
	 *@param String  searchObject,
	 *@return List<CDdMxEquipmentLookupSearchModel>
	 */
	public static List<CDdMxEquipmentLookupSearchModel> getIMEInumbers(String searchTerm, String recordId, String searchObject) {
		List<CDdMxEquipmentLookupSearchModel> results = new List<CDdMxEquipmentLookupSearchModel>();
		string FieldApiName = searchObject == TABLET_IMEI ? TABLET_IMEI_API : PRINTER_IMEI_API;
		// assign the field search based on the input tablet IMEI or printer IMEI.
		searchObject = searchObject == TABLET_IMEI ? TABLET_IMEI : PRINTER_IMEI;
		String val = '\'%' + String.escapeSingleQuotes(searchTerm.trim()) + '%\'';
		string query = 'select id,Tablet_Serial_Number__c,Printer_IMEI__c, (select id from Mx_Orders__r order by createddate desc limit 1) from case where AccountId =:recordId';
        if(string.isNotBlank(searchTerm)){
        query +=' and ' + FieldApiName + ' LIKE ' + val;    
        }
        query +=' and '+FieldApiName + ' != null and Request_Type__c != :RETURN_LABEL_REQUEST_TYPE order by createddate desc';
		List<sObject> sobjList = Database.query(query);
        /*for (Mx_Order_Item__c orderItem : [SELECT id, Mx_Order__c, Identifier__c FROM Mx_Order_Item__c WHERE Mx_Order__r.Account__c = :recordId AND Mx_Order__r.Type_Of_Mx_Order__c !=:TYPE_OF_ORDER_RETURN AND Identifier__c LIKE :'%' + searchTerm + '%']) {
			results.add(new CDdMxEquipmentLookupSearchModel(orderItem.Mx_Order__c, searchObject, IMEI_ICON, orderItem.Identifier__c, '', ORDER_IMEIObject, false));
		}*/
        for (sObject sobj : sobjList) {
            String sourceObject = CASE_IMEIObject;
            String sourceId = string.valueof(sobj.get('Id'));
            if(sobj.getSObjects('Mx_Orders__r') != null){
                sourceObject = ORDER_IMEIObject;
                sourceId = string.valueof((sobj.getSObjects('Mx_Orders__r'))[0].get('Id'));
            }
            results.add(new CDdMxEquipmentLookupSearchModel(sourceId, searchObject, IMEI_ICON, string.valueof(sobj.get(FieldApiName)), '', sourceObject, false));
        }        
		return results;
	}
	/**
	 *@description find the opportunity order protocol using store Id if opp is not selected.
	 *@param String storeId
	 *@return String 
	 */
	@AuraEnabled
	public static String getOrderProtocolFromMint(String storeId){
		try{
		CDdNimdaSyncMSService mxNimdaService = new CDdNimdaSyncMSService();
		Map<String, Object> storeInfo = (Map<String, Object>) JSON.deserializeUntyped(mxNimdaService.getStore(storeId));
		return string.valueof(storeInfo.get('order_protocol'));
		}catch(exception ex){
			throw new AuraHandledException('Error while getting store info for opportunity validation ' +ex.getmessage());
		}
	}

	/**
	 *@description findObjectNameFromRecordIdPrefix method for return object type based on the record Id.
	 *@param String recordId,
	 *@return String
	 */
	public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix) {
		String objectName = '';
        //Get prefix from record ID
        //This assumes that you have passed at least 3 characters
        String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0, 3);
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (Schema.SObjectType stype : gd.values()) {
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            //Check if the prefix matches with requested prefix
            if (prefix != null && prefix.equals(myIdPrefix)) {
                objectName = r.getName();
                break;
            }
        }
		return objectName;
	}
    public static Account getAccount(string actId){
        return [select id, RecordTypeId, Language__c, BillingCountryCode from Account where id = :actId];
    }
	/**
	*@description AuraException method to set the message for AuraHandledException.
	*@param String message,
	*@return String
	*/
	public static AuraHandledException AuraException(String message) {
		AuraHandledException e = new AuraHandledException(message);
		e.setMessage(message);
		return e;
	}
}