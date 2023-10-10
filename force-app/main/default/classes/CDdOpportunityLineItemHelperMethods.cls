/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 06/18/2020
*
* @author Jeremy Johnson (Perficient, Inc.)
* @date 07/30/2020
*
* @group Trigger Handler
*
* @description Trigger handler helper methods for Opportunity Line Item object
**********************************************************************************************************************/
public class CDdOpportunityLineItemHelperMethods {

	public static final String PRODUCT_ID_SEPARATOR = '; ';

	public static final String PRD_MAP_MDT = 'OLI_Prd_Default__mdt';
	public static final String PBE_MAP_MDT = 'OLI_Pbe_Default__mdt';

	private static final String PRD_OBJECT = 'Product2';
	private static final String PBE_OBJECT = 'PricebookEntry';
    private static final String SOBJECT_TYPE_OPPORTUNITY_LINE_ITEM = 'OpportunityLineItem';

	public static final String DELETION_ERROR_MESSAGE_CONTRACT_SIGNED =
			'You cannot delete Opportunity Products once the Opportunity contract is signed.'
					+ ' You must change the Opportunity Stage back to Ready for Signature first, and then resend the contract';
	public static final String DELETION_ERROR_MESSAGE_CLOSED_WON =
			'You cannot delete Opportunity Products once the Opportunity is Closed Won.';
    public static final String PRODUCT_FAMILY_BBOT = 'Bbot';
    public static final Map<String, Set<String>> corpProdValidationFieldSetForProdNames = new Map<String, Set<String>>();
    public static final Set<String> weeklyRevenueCalculationProductNames = new Set<String>();

    private static final Map<Id, Opportunity> oppUpdateUOW = new Map<Id, Opportunity>();

    private static Map<Id, Opportunity> opportunityMap;

    static{
        for (Opp_Product_Corp_Prod_Validation__mdt mdt : [SELECT Id, Product_Name__c, FieldSet_Name__c
                                                    FROM Opp_Product_Corp_Prod_Validation__mdt
                                                    WHERE Is_Active__c = true]){
            if (corpProdValidationFieldSetForProdNames.containsKey(mdt.FieldSet_Name__c)){
                corpProdValidationFieldSetForProdNames.get(mdt.FieldSet_Name__c).add(mdt.Product_Name__c);
            } else {
                corpProdValidationFieldSetForProdNames.put(mdt.FieldSet_Name__c, new Set<String>{mdt.Product_Name__c});
            }
        }
        for (Opp_Product_Weekly_Revenue__mdt mdt : [SELECT Id, Product_Name__c
                                                    FROM Opp_Product_Weekly_Revenue__mdt
                                                    WHERE Is_Active__c = true]){
            weeklyRevenueCalculationProductNames.add(mdt.Product_Name__c);
        }
    }   
    /**
     * @description BZAP-7965 & BZAP-8190: Set default values on OpportunityLineItem. The source of
     * default values is Product2 and PricebookEntry. Field mappings are defined in custom metadata.
     */
	public static void applyDefaults(List<OpportunityLineItem> newList) {
		List<Id> prdIds = new List<Id>();
		List<Id> pbeIds = new List<Id>();
		for (OpportunityLineItem oli : newList) {
			prdIds.add(oli.Product2Id);
			pbeIds.add(oli.PricebookEntryId);
		}

		Map<String, String> prdMap = getDefaultFieldMap(PRD_MAP_MDT);
		Map<String, String> pbeMap = getDefaultFieldMap(PBE_MAP_MDT);

		Map<Id, SObject> prds = getSourceObjects(PRD_OBJECT, String.join(prdMap.values(), ', '), prdIds);
		Map<Id, SObject> pbes = getSourceObjects(PBE_OBJECT, String.join(pbeMap.values(), ', '), pbeIds);

		for (OpportunityLineItem oli : newList) {
			applyDefaults(oli, prdMap, prds.get(oli.Product2Id));
			applyDefaults(oli, pbeMap, pbes.get(oli.PricebookEntryId));
		}
	}

	/**
	 * @description Retrieve a map of source/target fields for the given metadata type.
	 *
	 * @param metadataType the API name of the metadata type
	 * @return a Map of the target/source fields keyed by target
	 */
	@TestVisible
	private static Map<String, String> getDefaultFieldMap(String metadataType) {
		Map<String, String> defaultMap = new Map<String, String>();
		String soql = 'select Target_Field__c, Source_Field__c from ' + metadataType;
		for (SObject defaultMDT : Database.query(soql)) {
			String targetField = defaultMDT.get('Target_Field__c').toString();
			String sourcefield = defaultMDT.get('Source_Field__c').toString();
			defaultMap.put(targetField, sourcefield);
		}
		return defaultMap;
	}

	/**
	 * @description Retrieve records from the source object with the mapped fields.
	 *
	 * @param objName the source object to retrieve
	 * @param fields the fields to retrieve
	 * @param ids the ids to filter on, referenced by the new OpportunityLineItems
	 * @return a map of source objects keyed by Id
	 */
	private static Map<Id, SObject> getSourceObjects(String objName, String fields, List<Id> ids) {
		Map<Id, SObject> sourceMap = new Map<Id, SObject>();
		String soql = String.format('select Id, {0} from {1} where Id = :ids', new List<String> { fields , objName });
		for (SObject source : Database.query(soql)) {
			Id id = Id.valueOf(source.get('Id').toString());
			sourceMap.put(id, source);
		}
		return sourceMap;
	}

	/**
	 * @description Apply default values from the source object if the target field is null.
	 *
	 * @param targetObj the OpportunityLineItem to update
	 * @param fieldMap the source -> target field mapping
	 * @param sourceObj the source object providing default values
	 */
	private static void applyDefaults(OpportunityLineItem targetObj, Map<String, String> fieldMap, SObject sourceObj) {
		for (String targetField : fieldMap.keySet()) {
			if (targetObj.get(targetField) == null) {
				String sourceField = fieldMap.get(targetField);
				targetObj.put(targetField, sourceObj.get(sourceField));
			}
		}
	}

	/**
    * @description BZAP-8036 - Update Product_IDs__c on parent opportunities
    * Nathalie Mendezona - 08/18/2022 - BZAP-16317 for Bbot
    */
    public static void updateOpportunity(List<OpportunityLineItem> newList) {
        Set<Id> oppIds = new Set<Id>();

        for (OpportunityLineItem oli : newList) {
            oppIds.add(oli.OpportunityId);
        }

        for (Opportunity opp : getOpportunityMap(oppIds).values()) {
            List<Id> productIds = new List<Id>();
            Boolean hasBbotProduct = false;
            Integer bbotCount = 0;
            for (OpportunityLineItem oli : opp.OpportunityLineItems) {
                productIds.add(oli.Product2Id);
                if (oli.PricebookEntry.Product2.Family != null && oli.PricebookEntry.Product2.Family.contains(PRODUCT_FAMILY_BBOT)) {
                    hasBbotProduct = true;
                    bbotCount++;
                }
            }
            Opportunity updatedOpp = new Opportunity(Id = opp.Id, Product_IDs__c = String.join(productIds, PRODUCT_ID_SEPARATOR), Has_Bbot_Product__c = hasBbotProduct);
            if(bbotCount > 0 && bbotCount == opp.OpportunityLineItems.size()){
                updatedOpp.Has_Only_Bbot_Products__c=true;
            }else{
                updatedOpp.Has_Only_Bbot_Products__c=false;
            }
            oppUpdateUOW.put(updatedOpp.Id, updatedOpp);
        }
    }

	public static void preventOLIDeletionAfterContractSigned(Map<Id, OpportunityLineItem> oldRecords){
		for(OpportunityLineItem oli: [SELECT Id, Opportunity.StageName FROM OpportunityLineItem WHERE ID IN :oldRecords.keySet()
		AND Opportunity.StageName IN ('Contract Signed', 'Closed Won')]){
			String errorMessage =  (oli.Opportunity.StageName == 'Contract Signed')
					? DELETION_ERROR_MESSAGE_CONTRACT_SIGNED
					: DELETION_ERROR_MESSAGE_CLOSED_WON;
			oldRecords.get(oli.Id).addError(errorMessage);
		}
	}
    /**
    * @description Update fields on Opportunity Line Item records that meet the product criteria
    */
    public static void updateFieldsOnOppProducts(List<OpportunityLineItem> newList) {
        Map<String, Set<String>> oppLineItemsByProductName = getOppLineItemsByProductName(newList);
        updateCorporateProductValidation(oppLineItemsByProductName, newList);
        applyWeeklyRevenueCalculation(oppLineItemsByProductName, newList);
    }
    /**
    * @description BZAP-9090 - Update Corporate Product Validation field with 1 or 0
    */    
    private static void updateCorporateProductValidation(Map<String, Set<String>> oppLineItemsByProductName, List<OpportunityLineItem> newList){
        Map<String, OpportunityLineItem> oppProductsByUniqueKey = getOppProductsByUniqueKey(newList);
        Map<String, Map<String, SObject>> fieldSetOfRequiredFieldsForSObject = new Map<String, Map<String, SObject>>();
        for (String fieldSetName : corpProdValidationFieldSetForProdNames.keySet()){
            for (String productName : corpProdValidationFieldSetForProdNames.get(fieldSetName)){
                if (oppLineItemsByProductName.containsKey(productName)){
                    for (String oppLineItemKey : oppLineItemsByProductName.get(productName)){
                        if (fieldSetOfRequiredFieldsForSObject.containsKey(fieldSetName)){
                            fieldSetOfRequiredFieldsForSObject
                                        .get(fieldSetName)
                                        .put(oppLineItemKey, oppProductsByUniqueKey.get(oppLineItemKey));
                        } else {
                            fieldSetOfRequiredFieldsForSObject
                                        .put(fieldSetName, new Map<String, SObject>{oppLineItemKey => oppProductsByUniqueKey.get(oppLineItemKey)});
                        }
                    }
                }
            }
        }
        if (!fieldSetOfRequiredFieldsForSObject.isEmpty()){
            Map<String, Boolean> corporateProductValidationResult 
                = new CDdSObjectRequiredFieldsService(SOBJECT_TYPE_OPPORTUNITY_LINE_ITEM,
                                                    fieldSetOfRequiredFieldsForSObject)
                                                    .getSObjectResult();
            for (String oppLineItemKey : corporateProductValidationResult.keySet()){
                OpportunityLineItem oli = oppProductsByUniqueKey.get(oppLineItemKey);
                oli.Corporate_Product_Validation__c 
                            = corporateProductValidationResult.get(oppLineItemKey) ? 1 : 0; 
            }
        }   
    }
    /**
    * @description BZAP-9138 - Apply Weekly Revenue field calculation
    */    
    private static void applyWeeklyRevenueCalculation(Map<String, Set<String>> oppLineItemsByProductName, List<OpportunityLineItem> newList){
        Map<String, OpportunityLineItem> oppProductsByUniqueKey = getOppProductsByUniqueKey(newList);
        for (String productName : weeklyRevenueCalculationProductNames){
            if (oppLineItemsByProductName.containsKey(productName)){
                for (String oppLineItemKey : oppLineItemsByProductName.get(productName)){
                    OpportunityLineItem oli = oppProductsByUniqueKey.get(oppLineItemKey);
                    if (oli.TotalPrice!=null && oli.Weekly_Order_Frequency__c!=null){
                        oli.Weekly_Revenue__c = oli.TotalPrice * oli.Weekly_Order_Frequency__c;
                    }
                }
            }
        }
    }    
    /**
    * @description This private method will build a map of collection of Opp products grouped by product name
    */
    private static Map<String, Set<String>> getOppLineItemsByProductName(List<OpportunityLineItem> newList) {
        Set<Id> priceBookEntryIds = new Set<Id>();
        Map<String, Set<String>> oppLineItemsByProductName = new Map<String, Set<String>>();
        for (OpportunityLineItem oli : newList){
            if (String.isNotBlank(oli.OpportunityId)
                && String.isNotBlank(oli.PricebookEntryId)){
                priceBookEntryIds.add(oli.PricebookEntryId);
            }
        }
        for (PricebookEntry pbe: [SELECT Id, Product2.Name 
                                FROM PricebookEntry
                                WHERE Id IN :priceBookEntryIds]){
            for (OpportunityLineItem oli : newList){
                if (pbe.Id.equals(oli.PricebookEntryId)){
                    String key = getOppProductUniqueKey(oli);
                    if (oppLineItemsByProductName.containsKey(pbe.Product2.Name)){
                        oppLineItemsByProductName.get(pbe.Product2.Name).add(key);
                    } else { 
                        oppLineItemsByProductName.put(pbe.Product2.Name, new Set<String>{key});
                    }
                }
            }
        }
        return oppLineItemsByProductName;
    }
    /**
    * @description This private method will build a map of collection of Opp products with a unique key
    * For 'Before Insert' scenario, the key using composite references may be used
    * Note: This method expects the product to be associated with the Opportunity Line Item
    * via Price Book Entry (i.e. using the relevant price book) and also a Parent Opportunity needs
    * to be available on the Opportunity Line Item record
    */
    private static Map<String, OpportunityLineItem> getOppProductsByUniqueKey(List<OpportunityLineItem> newList) {
        Map<String, OpportunityLineItem> oppLineItemMap = new Map<String, OpportunityLineItem>();
        for (OpportunityLineItem oli : newList){
            String key = getOppProductUniqueKey(oli);
            if (String.isNotBlank(key)){
                oppLineItemMap.put(key, oli);
            }
        }
        return oppLineItemMap;
    }
    /**
    * @description This private method will return an unique Opportunity Product key
    * Return 'Record Id', if one exists on the Opportunity Product record
    * Else, construct a composite key using Parent Opportunity Id and the price Book Entry Id
    */    
    private static String getOppProductUniqueKey(OpportunityLineItem oli){
        String key = null;
        if (String.isNotBlank(oli.OpportunityId)
                && String.isNotBlank(oli.PricebookEntryId)){
            key = (String.isNotBlank(oli.Id) ? String.valueOf(oli.Id) : oli.OpportunityId + ':' + oli.PricebookEntryId);
        }
        return key;
    }

    /**
     * BZAP-9316: Disable PactSafe CW rule for Group Order / Gift Card Opportunities
     *
     * Whenever a new Oli is inserted or deleted, determine whether the Opportunity can bypass Pactsafe validation and
     * update Opportunity.Bypass_Pactsafe_Validation__c accordingly. Bypass_Pactsafe_Validation__c is used in conjunction
     * with a validation rule.
     *
     * Opportunities can bypass Pactsafe validation when 1) there are Group Order / Gift Card products on the
     * Opportunity and 2) there are no other product types on the Opportunity.
     *
     * @param oliMap The new OpportunityLineItems to evaluate
     */
    public static void disablePactSafeCWRule(Map<Id, OpportunityLineItem> oliMap) {
        Set<Id> bypassIdFilter = getPactSafeBypassFilter();
        Set<Id> oppIds = getOpportunityIds(oliMap);
        Map<Id, Set<Id>> olisByParentMap = getOlisByParentMap(oppIds, oliMap);
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([select Id, Bypass_Pactsafe_Validation__c from Opportunity where Id = :oppIds]);

        // Evaluate each Opportunity to determine if 1) they contain Group Order / Gift Card products and
        // 2) they contain other products.
        for (Id oppId : olisByParentMap.keySet()) {
            Opportunity opp = opps.get(oppId);
            Integer containsGiftOrGroupProduct = 0;
            Integer containsOtherProducts = 0;

            for (Id product2Id : olisByParentMap.get(oppId)) {
                if (bypassIdFilter.contains(product2Id)) {
                    containsGiftOrGroupProduct++;
                } else {
                    containsOtherProducts++;
                }
            }

            // For this Opportunity, determine whether Bypass_Pactsafe_Validation__c needs to be updated based on its current value
            if (containsGiftOrGroupProduct > 0 && containsOtherProducts == 0) {
                if (opp.Bypass_Pactsafe_Validation__c != true) {
                    if (oppUpdateUOW.containsKey(oppId)) {
                        oppUpdateUOW.get(oppId).Bypass_Pactsafe_Validation__c = true;
                    } else {
                        oppUpdateUOW.put(oppId, new Opportunity(Id = oppId, Bypass_Pactsafe_Validation__c = true));
                    }
                }
            } else {
                if (opp.Bypass_Pactsafe_Validation__c != false) {
                    if (oppUpdateUOW.containsKey(oppId)) {
                        oppUpdateUOW.get(oppId).Bypass_Pactsafe_Validation__c = false;
                    } else {
                        oppUpdateUOW.put(oppId, new Opportunity(Id = oppId, Bypass_Pactsafe_Validation__c = false));
                    }
                }
            }
        }
    }

    // BZAP-9316: Disable PactSafe CW rule for Group Order / Gift Card Opportunities
    private static Set<Id> getPactSafeBypassFilter() {
        // Get a set of Product2Ids from custom settings that define what constitutes a Group Order / Gift Card Opportunity
        Set<Id> bypassIdFilter = new Set<Id>();
        List<Bypass_Pactsafe_Validation__c> bypassFilters = [select Product2Id__c from Bypass_Pactsafe_Validation__c];
        for (Bypass_Pactsafe_Validation__c productFilterId : bypassFilters) {
            bypassIdFilter.add(productFilterId.Product2Id__c);
        }
        return bypassIdFilter;
    }

    // BZAP-9316: Disable PactSafe CW rule for Group Order / Gift Card Opportunities
    private static Set<Id> getOpportunityIds(Map<Id, OpportunityLineItem> opps) {
        // Get a set of Opportunity Ids for the given list of OpportunityLineItems (for bulkification)
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : opps.values()) {
            oppIds.add(oli.OpportunityId);
        }
        return oppIds;
    }

    // BZAP-9316: Disable PactSafe CW rule for Group Order / Gift Card Opportunities
    private static Map<Id, Set<Id>> getOlisByParentMap(Set<Id> oppIds, Map<Id, OpportunityLineItem> oliMap) {
        Map<Id, Set<Id>> olisByParentMap = new Map<Id, Set<Id>>();
        List<OpportunityLineItem> olis = [select Id, Product2Id, OpportunityId from OpportunityLineItem where OpportunityId = :oppIds];

        for (OpportunityLineItem oli : olis) {
            if (oliMap.keySet().contains(oli.Id) && oliMap.get(oli.Id).IsDeleted) { // exclude deleted
                // Skip
            } else {
                if (olisByParentMap.containsKey(oli.OpportunityId)) {
                    olisByParentMap.get(oli.OpportunityId).add(oli.Product2Id);
                } else {
                    olisByParentMap.put(oli.OpportunityId, new Set<Id> { oli.Product2Id });
                } 
            }
        }

        // provide an empty set for last deleted oli
        for (Id oppId : oppIds) {
            if (!olisByParentMap.containsKey(oppId)) {
                olisByParentMap.put(oppId, new Set<Id>());
            }
        }
        return olisByParentMap;
    }

    public static void finishOpportunityUOW() {
        update oppUpdateUOW.values();
    }

    /**
     * Method to query opportunities and store in a map. Reused by multiple methods
     */
    private static Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIds) {
        opportunityMap = new Map<Id, Opportunity>(
                            [SELECT Id, StageName, RecordTypeId,
                                (SELECT Id, PricebookEntry.Product2.Family, Product2Id, Product2.Product_ID18__c FROM OpportunityLineItems)
                            FROM Opportunity
                            WHERE Id IN :oppIds]);
        return opportunityMap;
    }

    /**
     * Migrated from Process Builder: Opportunity Product Automation FOPO and/or OA&S
     * FOPO stands for 'First Order, Percentage Off', and OA&S stands for 'Order Again'
     * BZAP-17786 Nathalie Mendezona
     */
    public static void fopoAndOrOAS(List<OpportunityLineItem> newList, Map<Id, OpportunityLineItem> oldMap) {
        Set<String> recordTypeIdsToInclude = new Set<String>{CDdOpportunityTriggerHelper.oppMarketplaceRTId,
                                                             CDdOpportunityTriggerHelper.oppPostSaleRTId};
        Set<String> oppStagesToExclude = new Set<String>{CDdOpportunityTriggerHelper.STAGE_NAME_OUT_FOR_SIGNATURE,
                                                         CDdOpportunityTriggerHelper.STAGE_NAME_CONTRACT_SIGNED,
                                                         CDdOpportunityTriggerHelper.STAGE_NAME_CLOSED_WON,
                                                         CDdOpportunityTriggerHelper.STAGE_NAME_CLOSED_LOST};
        Set<Id> oppIds = new Set<Id>();

        String pricebooksToExclude = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.OPPLINETRIGGER_FOPO_OR_OAS_PRICEBOOKS);
        String productsToInclude = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.OPPLINETRIGGER_FOPO_OR_OAS_PRODUCTS);

        if (Test.isRunningTest()) {
            Set<String> pbeIds = new Map<String, PricebookEntry>([SELECT Id, Name FROM PricebookEntry WHERE (Product2.Name = 'Order Again' OR Product2.Name = 'First Order, Percentage Off') AND CurrencyIsoCode = 'USD']).keySet();
            List<String> pbeIdList = new List<String>(pbeIds);
            pricebooksToExclude = String.join(pbeIdList,',');
            Set<String> productiIds = new Map<String, Product2>([SELECT Id, Name FROM Product2 WHERE Name = 'Order Again' OR Name = 'First Order, Percentage Off']).keySet();
            List<String> productIdList = new List<String>(productiIds);
            productsToInclude = String.join(productIdList,',');
        }

        for (OpportunityLineItem oli: newList) {
            if (!pricebooksToExclude.contains(oli.PricebookEntryId)
                && productsToInclude.contains(oli.Product2Id)) {
                oppIds.add(oli.OpportunityId);
            }
        }
        getOpportunityMap(oppIds);

        for (OpportunityLineItem oli: newList) {
            Opportunity opp = opportunityMap.get(oli.OpportunityId);
            if (opp == null || oppStagesToExclude.contains(opp.StageName)) {
                continue;
            }
            if (recordTypeIdsToInclude.contains(opp.RecordTypeId)) {
                if (oldMap == null) {
                    //Additional Marketing Fee Rate - set to 0 if null
                    Decimal mktOnlyCommission = getDecimalValue(oli.Marketing_Only_Commission__c);
                    // Discount Percentage for Consumer - set to 0 if null
                    Decimal discountPercentage = getDecimalValue(oli.Discount_Percentage__c);

                    // Discount Percentage for Consumer - calculation
                    oli.Discount_Percentage__c = oli.Discount_Percentage__c == null ?
                                                 mktOnlyCommission * 100 : discountPercentage * 100;

                                                 // Max Discount Amount for Consumer - calculation
                    oli.Max_Discount__c = oli.Max_Discount__c == null ?
                                          oli.Max_Amount_From_Marketing_Percent__c : oli.Max_Discount__c;
                } else { // is update
                    Map<Decimal, Decimal> commissionToPercent = new Map<Decimal, Decimal>  {
                        0.15 => 4,
                        0.2  => 5,
                        0.25 => 6
                    };
                    // Max Amount From Marketing Percent - calculation
                    Decimal mktCommissionToPercent = commissionToPercent.get(oli.Marketing_Only_Commission__c);
                    if (mktCommissionToPercent == null) {
                        mktCommissionToPercent = oli.Max_Amount_From_Marketing_Percent__c;
                    }
                    oli.Max_Amount_From_Marketing_Percent__c = oli.Max_Amount_From_Marketing_Percent__c == null ?
                                                               mktCommissionToPercent : oli.Max_Amount_From_Marketing_Percent__c;
                    // Max Discount Amount for Consumer - calculation
                    if (mktCommissionToPercent == null) {
                        mktCommissionToPercent = oli.Max_Discount__c;
                    }
                    oli.Max_Discount__c = oli.Max_Discount__c == null ? mktCommissionToPercent : oli.Max_Discount__c;
                }
            }
        }
    }

    private static Decimal getDecimalValue(Decimal fieldDecimal) {
        return (fieldDecimal == null ? 0.0 : fieldDecimal);
    }
}