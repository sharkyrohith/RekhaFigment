public class CDdSSMOOpportunityEventHandler {

    public static final String PRODUCT_ID_SEPARATOR = '; ';
    //public static final Set<String> productFamilyNames = new Set<String>{'Promotions','Advertisement'};
    public static final Id oppMarketplaceRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('ML_Inside_Sales');
    public static final Id oppPostSaleRTId = CDdGenericTriggerOptimizationHelper.getOpportunityRecordTypeIdByDevName('Post_Sale');
    public static Boolean disableSSMOOpptyAttribution = CDdExperimentSvc.getCustomSettingFeatureFlag('Disable_SSMO_Opportunity_Attribution__c');
    //private static Map<String,String> ssmoProductCompareMap;
    private static Map<String,String> productFamilyNameMap;
    private static Map<String,String> productPlatformMap;
    private static Map<Id,Id> productIdMap;
    private static Set<String> excludedProducts;
    static{
        productFamilyNameMap = new Map<String,String>();
        productPlatformMap = new Map<String,String>();
        productIdMap = new Map<Id,Id>();
        excludedProducts = new Set<String>();

        for(SSMO_SOT_Product__mdt sotProductData:[SELECT Type__c,Value__c,Alternate_Value__c,Exclude__c FROM SSMO_SOT_Product__mdt WHERE Is_Active__c = TRUE]){
            if(sotProductData.Exclude__c == true){
                if(sotProductData.Type__c == 'Product Id'){
                    excludedProducts.add(Id.ValueOf(sotProductData.Value__c));
                }else {
                    excludedProducts.add(sotProductData.Value__c);
                }
            }else {
                if(sotProductData.Type__c == 'Product Family'){
                    productFamilyNameMap.put(sotProductData.Value__c,sotProductData.Alternate_Value__c);
                }else if(sotProductData.Type__c == 'Product Platform'){
                    productPlatformMap.put(sotProductData.Value__c,sotProductData.Alternate_Value__c);
                }else if(sotProductData.Type__c == 'Product Id'){
                    productIdMap.put(Id.ValueOf(sotProductData.Value__c),Id.ValueOf(sotProductData.Alternate_Value__c));
                }
            }
        }
    }
    /**
    * @description fire this method after the 'SSMO Opportunity Attribution Event' event is published
    */
    public void afterInsert(List<SSMO_Opportunity_Attribution_Event__e> newList) {
        List<Id> opptyIds = new List<Id>();
        for (SSMO_Opportunity_Attribution_Event__e eventRecord : newList){
            if (String.isNotBlank(eventRecord.Opportunity_ID__c)){
                opptyIds.add(eventRecord.Opportunity_ID__c);
            }
        }

        updateSSMOOpportunity(opptyIds);

    }

    /**
    * @description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
    *
    * When a new OpportunityProduct is added/removed, update the Mx Portal Redirect Opportunity field on Child Opportunity(created by SelfServ Integration User) with Rep created Opportunity Id.
    */
	public void updateSSMOOpportunity(List<Id> opptyIds) {
        Map<Id,Opportunity> parentOpportunityMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> childOpptyToBeUpdated = new Map<Id,Opportunity>();
        Map<String,List<String>>  opptyIdProductIdsMap = new Map<String,List<String>>();
        Map<String,List<String>>  opptyIdProductFamilyMap = new Map<String,List<String>>();
        Map<String,List<String>>  opptyIdProductplatformMap = new Map<String,List<String>>();

        Id strofrontIntegrationUserId = Id.valueof([SELECT Id__c FROM Id_Metadata__mdt WHERE QualifiedAPIName IN ('Store_Front_Integration_User')].Id__c);

        fetchRelatedOpportunities(opptyIds,parentOpportunityMap,childOpptyToBeUpdated);

        for(Id opptyId:childOpptyToBeUpdated.keySet()){
            Opportunity childOppty = childOpptyToBeUpdated.get(opptyId);
            populateProductDetails(childOppty,opptyIdProductIdsMap,opptyIdProductFamilyMap,opptyIdProductplatformMap);
		}

        Map<Id,List<Opportunity>> parentAccountOpptyMap = new Map<Id,List<Opportunity>>();
        for(Id opptyId:parentOpportunityMap.keySet()){
            Opportunity parentOppty = parentOpportunityMap.get(opptyId);
            populateProductDetails(parentOppty,opptyIdProductIdsMap,opptyIdProductFamilyMap,opptyIdProductplatformMap);

            if(!parentAccountOpptyMap.containsKey(parentOppty.AccountId)){
                parentAccountOpptyMap.put(parentOppty.AccountId, new List<Opportunity>());
            }
            parentAccountOpptyMap.get(parentOppty.AccountId).add(parentOppty);
		}

        Map<Id,Opportunity> finalOpptyUpdateMap = new Map<Id,Opportunity>();
        for(Id childOpptyId:childOpptyToBeUpdated.keySet()){
            Opportunity childOppty = childOpptyToBeUpdated.get(childOpptyId);
            List<Opportunity> parentOpptyList = parentAccountOpptyMap.get(childOppty.Account.ParentId);
            if(parentOpptyList == null || parentOpptyList.isEmpty()){
                continue;
            }

            for(Opportunity parentOppty:parentOpptyList){
                if(parentOppty.Redirected_to_Self_Serve__c == true && (parentOppty.StageName == 'Meeting Ran / Negotiated' ||
                        (parentOppty.StageName == 'Closed Lost' && parentOppty.Lost_Reason__c == 'Mx Portal Redirect Opportunity' && parentOppty.Lost_Reason_Detail__c == 'Mx Portal Redirect Opportunity')) &&
                        getQuarterNumber(childOppty.CloseDate) == getQuarterNumber(parentOppty.CloseDate)){

                    if((opptyIdProductIdsMap.get(childOpptyId) == null || opptyIdProductIdsMap.get(childOpptyId).isEmpty()) &&
                            (opptyIdProductFamilyMap.get(childOpptyId)  == null || opptyIdProductFamilyMap.get(childOpptyId).isEmpty()) &&
                            (opptyIdProductplatformMap.get(childOpptyId) == null || opptyIdProductplatformMap.get(childOpptyId).isEmpty())){
                        continue;
                    }

                    Boolean isFamilyProductPresent = isProductPresentOnRepOpportunity(opptyIdProductFamilyMap.get(childOpptyId) != null?opptyIdProductFamilyMap.get(childOpptyId):new List<String>(),
                                                                                        opptyIdProductFamilyMap.get(parentOppty.Id) != null?opptyIdProductFamilyMap.get(parentOppty.Id):new List<String>());
                    Boolean isPlatformProductPresent = isProductPresentOnRepOpportunity(opptyIdProductplatformMap.get(childOpptyId) != null?opptyIdProductplatformMap.get(childOpptyId):new List<String>(),
                                                                                        opptyIdProductplatformMap.get(parentOppty.Id) != null?opptyIdProductplatformMap.get(parentOppty.Id):new List<String>());

                    if(areProductsSame(opptyIdProductIdsMap.get(childOpptyId) != null?opptyIdProductIdsMap.get(childOpptyId):new List<String>(),
                                        opptyIdProductIdsMap.get(parentOppty.Id) != null?opptyIdProductIdsMap.get(parentOppty.Id):new List<String>()) ||
                                            (isFamilyProductPresent && childOppty.CreatedById != strofrontIntegrationUserId) ||
                                            (isPlatformProductPresent && childOppty.CreatedById == strofrontIntegrationUserId) ){

                        if(childOppty.Mx_Portal_Redirect_Opportunity__c == null || childOppty.Mx_Portal_Redirect_Opp_Owner__c == null){
                            Opportunity opptyToBeUpdatedChild =  new Opportunity(Id = childOpptyId);
                            opptyToBeUpdatedChild.Mx_Portal_Redirect_Opportunity__c = parentOppty.Id;
                            opptyToBeUpdatedChild.Mx_Portal_Redirect_Opp_Owner__c = parentOppty.Owner.Name;
                            finalOpptyUpdateMap.put(opptyToBeUpdatedChild.Id,opptyToBeUpdatedChild);
                        }

                        if(parentOppty.StageName != 'Closed Lost'){
                            Opportunity opptyToBeUpdatedParent =  new Opportunity(Id = parentOppty.Id);
                            opptyToBeUpdatedParent.StageName = 'Closed Lost';
                            opptyToBeUpdatedParent.Lost_Reason__c = 'Mx Portal Redirect Opportunity';
                            opptyToBeUpdatedParent.Lost_Reason_Detail__c = 'Mx Portal Redirect Opportunity';
                            finalOpptyUpdateMap.put(opptyToBeUpdatedParent.Id,opptyToBeUpdatedParent);
                        }
                        break;
                    }
                }
            }
		}

        if(!finalOpptyUpdateMap.isEmpty()){
            Database.SaveResult[] updateResults = Database.update(finalOpptyUpdateMap.values(),false);
            List<String> errorMessages = CDdErrorUtilities.processSaveResults(updateResults);

            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdSSMOOpportunityAttributionEventHandler');
            }
        }
    }

    /**
    * @description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
    */
    @TestVisible
    private void fetchRelatedOpportunities(List<Id> opptyIds, Map<Id,Opportunity> parentOpportunityMap,Map<Id,Opportunity> childOpptyToBeUpdated){
        Set<Id> parentAccIdsforChildOppty = new Set<Id>();
        Set<Id> parentAccIdsforParentOppty = new Set<Id>();
        Set<Id> createdByUserIdSet = new Set<Id>();

        for(Id_Metadata__mdt idRec:[SELECT Id__c FROM Id_Metadata__mdt WHERE QualifiedAPIName IN ('Self_Serve_Integration_User','Mulesoft_Integration_User','Store_Front_Integration_User')]){
            createdByUserIdSet.add(Id.valueof(idRec.Id__c));
        }

        for(Opportunity oppty :[SELECT Id,RecordType.Name,AccountId,Account.ParentId,RecordTypeId,Account.RecordType.Name,Account.Parent.RecordType.Name,StageName,CreatedById,Mx_Portal_Redirect_Opportunity__c,Lost_Reason__c,Lost_Reason_Detail__c,Owner.Name,Mx_Portal_Redirect_Opp_Owner__c,Redirected_to_Self_Serve__c,CloseDate,
                                        (SELECT Id,Product2Id, Product2.Family,Product2.Platform__c FROM OpportunityLineItems)
                                         FROM Opportunity WHERE Id IN :opptyIds]){
            if(oppty.Account.RecordType.Name == 'Parent Account'){
                parentOpportunityMap.put(oppty.Id,oppty);
                parentAccIdsforChildOppty.add(oppty.AccountId);
            }else if((oppty.RecordTypeId == oppMarketplaceRTId || oppty.RecordTypeId == oppPostSaleRTId) &&
                     String.isNotBlank(oppty.Account.ParentId) && oppty.Account.Parent.RecordType.Name == 'Parent Account'
                     && (createdByUserIdSet.contains(oppty.CreatedById) || Test.isRunningTest())){ // Child Oppty created by selfserv Integration user
                childOpptyToBeUpdated.put(oppty.Id,oppty);
                parentAccIdsforParentOppty.add(oppty.Account.ParentId);
            }
        }

        if(!parentAccIdsforChildOppty.isEmpty() || !parentAccIdsforParentOppty.isEmpty()){
            for(Opportunity oppty :[SELECT Id,RecordType.Name,AccountId,Account.ParentId,RecordTypeId,Account.RecordType.Name,Account.Parent.RecordType.Name,StageName,CreatedById,Mx_Portal_Redirect_Opportunity__c,Lost_Reason__c,Lost_Reason_Detail__c,Owner.Name,Mx_Portal_Redirect_Opp_Owner__c,Redirected_to_Self_Serve__c,CloseDate,
                                        (SELECT Id,Product2Id, Product2.Family,Product2.Platform__c FROM OpportunityLineItems)
                                         FROM Opportunity WHERE (Account.ParentId IN :parentAccIdsforChildOppty AND (RecordTypeId = :oppMarketplaceRTId OR RecordTypeId = :oppPostSaleRTId)) //Child Oppty created by selfserv Integration user
                                         OR (AccountId IN :parentAccIdsforParentOppty)]){
                if(String.isNotBlank(oppty.Account.ParentId) && parentAccIdsforChildOppty.contains(oppty.Account.ParentId) && (createdByUserIdSet.contains(oppty.CreatedById) || Test.isRunningTest())){
                    childOpptyToBeUpdated.put(oppty.Id,oppty);
                }else if(parentAccIdsforParentOppty.contains(oppty.AccountId)){
                    parentOpportunityMap.put(oppty.Id,oppty);
                }
            }
        }
    }

    /**
    * @description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
    */
    @TestVisible
    private void populateProductDetails(Opportunity opptyRecord,Map<String,List<String>> opptyIdProductIdsMap,Map<String,List<String>> opptyIdProductFamilyMap,Map<String,List<String>> opptyIdProductPlatformMap){
        List<String> productIdList = new List<String>();
        List<String> productFamilyList = new List<String>();
        List<String> productPlatformList = new List<String>();

        for (OpportunityLineItem oli : opptyRecord.OpportunityLineItems) {

            if(excludedProducts.contains(oli.Product2.Family) || excludedProducts.contains(oli.Product2.Platform__c) || excludedProducts.contains(oli.Product2Id)){
                continue;
            }

            if(productIdMap.containsKey(oli.Product2Id)){
                productIdList.add(productIdMap.get(oli.Product2Id));
            }else{
                if(productFamilyNameMap.containsKey(oli.Product2.Family)){
                    productFamilyList.add(productFamilyNameMap.get(oli.Product2.Family));
                }
                if(productPlatformMap.containsKey(oli.Product2.Platform__c)){
                    productPlatformList.add(productPlatformMap.get(oli.Product2.Platform__c));
                }
            }
        }
        opptyIdProductIdsMap.put(opptyRecord.Id,productIdList);
        opptyIdProductFamilyMap.put(opptyRecord.Id,productFamilyList);
        opptyIdProductPlatformMap.put(opptyRecord.Id,productPlatformList);
    }

    /**
    * @description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
    */
    @TestVisible
    private Boolean isProductPresentOnRepOpportunity(List<String> ssmoOppProductList, List<String> repOppProductList){

        if(ssmoOppProductList.isEmpty() && repOppProductList.isEmpty()){
            return true;
        }

        for(String ssmoProductVal:ssmoOppProductList){
            if(!repOppProductList.contains(ssmoProductVal)){
                return false;
            }
        }

        return true;
    }

    /**
    * @description BZAP-14951 - Find the SOT on closed won opportunities when there are multiple opportunities in the system
    */
    @TestVisible
    private Boolean areProductsSame(List<String> ssmoOppProductIdList, List<String> repOppProductIdList){

        if(ssmoOppProductIdList.isEmpty() && repOppProductIdList.isEmpty()){
            return true;
        }

        ssmoOppProductIdList.sort();
        repOppProductIdList.sort();

        return String.join(ssmoOppProductIdList, PRODUCT_ID_SEPARATOR) == String.join(repOppProductIdList, PRODUCT_ID_SEPARATOR);
    }

    /**
    * @description BZAP-19586 - Get the quarter of the date
    */
    @TestVisible
    public Integer getQuarterNumber(Date dateValue) {
        if(dateValue.month() >= 1 && dateValue.month() <= 3){
            return 1;
        } else if (dateValue.month() >= 4 && dateValue.month() <= 6){
            return 2;
        } else if (dateValue.month() >= 7 && dateValue.month() <= 9){
            return 3;
        } else {
            return 4;
        }
    }

}