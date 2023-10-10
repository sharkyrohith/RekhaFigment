/**
* @author Ed
* @date 2021-06
* @description BZAP-11027, 11032 Merchant_Category__c Trigger Handler, update either account or lead
*/
public class CDdMerchantCategoryTriggerHandler {
    public static Boolean setAccountMerchantCategoriesv2_triggered = false;
    // static CDdVerticalCategoryHelper helper = ;
    public static Map<Id, Vertical_Category_Ids__c> MxCatIdSettingMap = CDdVerticalCategoryHelper.vertCatIdSettingMap;
    public static Vertical_Category_Trigger_Setting__c verticalCatFeatureFlags = Vertical_Category_Trigger_Setting__c.getOrgDefaults();

    public CDdMerchantCategoryTriggerHandler() {
        // helper = new CDdVerticalCategoryHelper();
        // MxCatIdSettingMap = helper.getVertCatSettings();
    }

    public void beforeInsert(List<Merchant_Category__c> newList) {
        if (verticalCatFeatureFlags.Disable_All__c) return;
        
        validateMxCategories(newList, null);
        updateObjMxCategoryList(newList);
        setAccountPrimaryCategory(newList);
        setLeadPrimaryCategory(newList);
    }

    public void beforeUpdate(Map<Id, Merchant_Category__c> newMap, Map<Id, Merchant_Category__c> oldMap) {
        if (verticalCatFeatureFlags.Disable_All__c) return;

        validateMxCategories(newMap.values(), oldMap);
    }

    public void beforeDelete(Map<Id, Merchant_Category__c> oldMap) {
        if (verticalCatFeatureFlags.Disable_All__c) return;
        
        preventPrimaryDeletion(oldMap.values());
        updateObjMxCategoryList(oldMap.values(), true);
    }

    public void validateMxCategories(List<Merchant_Category__c> newList, Map<Id, Merchant_Category__c> oldMap) {
        Map <Id, Merchant_Category__c> otherMxCategories = new Map<Id, Merchant_Category__c>();
        List<Id> leadIdList = new List<Id>();
        List<Id> acctIdList = new List<Id>();

        Map<Id, Merchant_Category__c> acctIdToMxCatMap = new Map<Id, Merchant_Category__c>();
        Map<Id, Merchant_Category__c> leadIdToMxCatMap = new Map<Id, Merchant_Category__c>();
        Merchant_Category__c currMxCategory;
        String currMxCategoryName;
        Integer otherMxCategoryCount;

        Set<Id> acctPrimaryFieldChecks = new Set<Id>();
        Set<Id> leadPrimaryFieldChecks = new Set<Id>();
        Set<Id> acctPrimaryCategoryChecks = new Set<Id>();
        Set<Id> leadPrimaryCategoryChecks = new Set<Id>();

        for (Merchant_Category__c currMxCat : newList) {
            if (((currMxCat.Account__c != null && currMxCat.Lead__c != null) || (currMxCat.Account__c == null && currMxCat.Lead__c == null)) &&
                !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                currMxCat.addError(Label.MC_Junction_Validation);
                continue;
            }

            if (!CDdVerticalCategoryHelper.handleMerchantCategoriesFlag && !CDdVerticalCategoryHelper.updatingPrimaryFlags && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                if (currMxCat.Primary__c && oldMap == null) {
                    if (currMxCat.Account__c != null) {
                        acctPrimaryFieldChecks.add(currMxCat.Account__c);
                    } else if (currMxCat.Lead__c != null) {
                        leadPrimaryFieldChecks.add(currMxCat.Lead__c);
                    }
                    continue;
                } else if (!currMxCat.Primary__c && oldMap == null) {
                    if (currMxCat.Account__c != null) {
                        acctPrimaryCategoryChecks.add(currMxCat.Account__c);
                    } else if (currMxCat.Lead__c != null) {
                        leadPrimaryCategoryChecks.add(currMxCat.Lead__c);
                    }
                } else if ((oldMap != null && currMxCat.Primary__c != oldMap.get(currMxCat.Id).Primary__c)) {
                    currMxCat.addError(Label.MC_PrimaryField_Validation);
                }
            }

            if (currMxCat.Account__c != null) acctIdToMxCatMap.put(currMxCat.Account__c, currMxCat);
            if (currMxCat.Lead__c != null) leadIdToMxCatMap.put(currMxCat.Lead__c, currMxCat);
        }

        if (!acctPrimaryFieldChecks.isEmpty() && [SELECT Id FROM Merchant_Category__c WHERE Account__c in :acctPrimaryFieldChecks].size() != 0) {
            newList[0].addError(Label.MC_PrimaryField_Validation);
        }

        if (!leadPrimaryFieldChecks.isEmpty() && [SELECT Id FROM Merchant_Category__c WHERE Lead__c in :leadPrimaryFieldChecks].size() != 0) {
            newList[0].addError(Label.MC_PrimaryField_Validation);
        }

        if (!acctPrimaryCategoryChecks.isEmpty() && [SELECT Id FROM Merchant_Category__c WHERE Account__c in :acctPrimaryCategoryChecks].size() == 0) {
            newList[0].addError(Label.MC_Primary_Category_Validation);
        }

        if (!leadPrimaryCategoryChecks.isEmpty() && [SELECT Id FROM Merchant_Category__c WHERE Lead__c in :leadPrimaryCategoryChecks].size() == 0) {
            newList[0].addError(Label.MC_Primary_Category_Validation);
        }

        // ADD custom setting
        if (acctIdToMxCatMap.size() > 0 && !verticalCatFeatureFlags.Merchant_Category_Validation_Is_Disabled__c 
            && !CDdVerticalCategoryHelper.handleMerchantCategoriesFlag && !CDdVerticalCategoryHelper.updatingPrimaryFlags) {
            for  (Account currAcct: [SELECT Id, Merchant_Categories__c, Primary_Merchant_Category__c FROM Account WHERE Id in :acctIdToMxCatMap.keySet()]) {
                if (acctIdToMxCatMap.containsKey(currAcct.Id)) {
                    currMxCategory = acctIdToMxCatMap.get(currAcct.Id);
                    currMxCategoryName = getCategoryNameForMxCatId(currMxCategory.Vertical_Category__c);
                    if (currAcct.Merchant_Categories__c != null && currAcct.Merchant_Categories__c.contains(currMxCategoryName)) {
                        currMxCategory.addError(Label.MC_Duplicate_Validation_Account);
                        continue;
                    }
                }
            }
        }

        if (leadIdToMxCatMap.size() > 0 && !verticalCatFeatureFlags.Merchant_Category_Validation_Is_Disabled__c 
            && !CDdVerticalCategoryHelper.handleMerchantCategoriesFlag && !CDdVerticalCategoryHelper.updatingPrimaryFlags) {
            for  (Lead currLead: [SELECT Id, Merchant_Categories__c, Primary_Merchant_Category__c FROM Lead WHERE Id in :leadIdToMxCatMap.keySet()]) {
                if (leadIdToMxCatMap.containsKey(currLead.Id)) {
                    currMxCategory = leadIdToMxCatMap.get(currLead.Id);
                    currMxCategoryName = getCategoryNameForMxCatId(currMxCategory.Vertical_Category__c);
                    if (currLead.Merchant_Categories__c != null && currLead.Merchant_Categories__c.contains(currMxCategoryName)) {
                        currMxCategory.addError(Label.MC_Duplicate_Validation_Lead);
                        continue;
                    }
                }
            }
        }


    }

    /**
    * @description Set Account.Primary_Merchant_Category__c primary flag to true if Merchant_Category__c primary flag is true
    **/
    public static void setAccountPrimaryCategory(List<Merchant_Category__c> newList) {
        List<Account> updateAccts = new List<Account>();
        Set<Id> updateAcctIds = new Set<Id>();

        for (Merchant_Category__c currMxCategory : newList) {
            if (currMxCategory.Account__c != null && !updateAcctIds.contains(currMxCategory.Account__c) && currMxCategory.Primary__c == true) {
                updateAcctIds.add(currMxCategory.Account__c);
                updateAccts.add(new Account(Id = currMxCategory.Account__c, 
                                            Primary_Merchant_Category__c = getCategoryNameForMxCatId(currMxCategory.Vertical_Category__c)));
            }
        }
        update updateAccts;
    }

    /**
    * @description Set Lead.Primary_Merchant_Category__c primary flag to true if Merchant_Category__c primary flag is true
    **/
    public static void setLeadPrimaryCategory(List<Merchant_Category__c> newList) {
        List<Lead> updateLeads = new List<Lead>();
        Set<Id> updateLeadIds = new Set<Id>();

        for (Merchant_Category__c currMxCategory : newList) {
            if (currMxCategory.Lead__c != null && !updateLeadIds.contains(currMxCategory.Lead__c) && currMxCategory.Primary__c == true) {
                updateLeadIds.add(currMxCategory.Lead__c);
                updateLeads.add(new Lead(Id = currMxCategory.Lead__c, 
                                         Primary_Merchant_Category__c = getCategoryNameForMxCatId(currMxCategory.Vertical_Category__c)));
            }
        }
        update updateLeads;
    }

    public static void updateObjMxCategoryList(List<Merchant_Category__c> newList) {
        updateObjMxCategoryList(newList, false);
    }

    public static void preventPrimaryDeletion(List<Merchant_Category__c> oldList) {
        for (Merchant_Category__c currMxCat : oldList) {
            if ((currMxCat.Primary__c && !CDdVerticalCategoryHelper.deletingAllMxCatFlag) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                currMxCat.addError(Label.MC_PrimaryDelete_Validation);
            }
        }
    }

    // TODO could use a rewrite
    // 1. retrieve a Map<accountId, Map<catname, List<subcatname>>> from a list of mx categories
    // 2. Query account for current Verticals value
    // 3. make the above into a map via account helper function
    // 4. combine maps, for each account
    // 5. Create list of Accounts with new vertical categories to update
    // 6. Transform into string
    public static void updateObjMxCategoryList(List<Merchant_Category__c> newList, Boolean isDelete) {
        if (CDdVerticalCategoryHelper.handleMerchantCategoriesFlag || setAccountMerchantCategoriesv2_triggered || System.isFuture()) return;
        
        Map<Id, Map<String, List<String>>> newObjIdMxCatMappingMap = new Map<Id, Map<String, List<String>>>();
        Map<Id, String> newObjIdMxCatValueMap = new Map<Id, String>();
        List<Id> newObjIdList = new List<Id>();
        List<Account> acctList = new List<Account>();
        List<Lead> leadList = new List<Lead>();
        Map<String, List<String>> OldAcctIdMxCatValueMap;
        Map<Id, Map<String, List<String>>> oldAcctIdMxCatMappingMap = new Map<Id, Map<String, List<String>>>();
        Map<String, List<String>> OldLeadIdMxCatValueMap;
        Map<Id, Map<String, List<String>>> oldLeadIdMxCatMappingMap = new Map<Id, Map<String, List<String>>>();
        Set<Id> oldAccountIds = oldAcctIdMxCatMappingMap.keySet();
        Set<Id> oldLeadIds = oldLeadIdMxCatMappingMap.keySet();

        // 1. retrieve a Map<SObjId, Map<catname, List<subcatname>>> from a list of mx categories 
        newObjIdMxCatMappingMap = CDdVerticalCategoryHelper.generateMxCatMapping(newList);

        // 2. Query account for current Verticals value
        if (newObjIdMxCatMappingMap.size() > 0) {
            acctList = [SELECT Id, Merchant_Categories__c FROM Account WHERE Id in :newObjIdMxCatMappingMap.keySet()];
            leadList = [SELECT Id, Merchant_Categories__c FROM Lead WHERE Id in :newObjIdMxCatMappingMap.keySet()];
        }

        // 3. convert existing account's vertical categories into a map Map<Id, List<Id>> via account helper function
        for (Account currAcct: acctList) {
            OldAcctIdMxCatValueMap = CDdVerticalCategoryHelper.convertIdMapToNameMap(CDdVerticalCategoryHelper.parseMerchantCategoryValues(currAcct.Merchant_Categories__c));
            oldAcctIdMxCatMappingMap.put(currAcct.Id, OldAcctIdMxCatValueMap);
        }
        for (Lead currLead: leadList) {
            OldLeadIdMxCatValueMap = CDdVerticalCategoryHelper.convertIdMapToNameMap(CDdVerticalCategoryHelper.parseMerchantCategoryValues(currLead.Merchant_Categories__c));
            oldLeadIdMxCatMappingMap.put(currLead.Id, OldLeadIdMxCatValueMap);
        }
        
        // 4. combine maps, for each obj
        Map<Id, Map<String, List<String>>> joinAcctIdMxCatMappingMap = new Map<Id, Map<String, List<String>>>();
        Map<Id, Map<String, List<String>>> joinLeadIdMxCatMappingMap = new Map<Id, Map<String, List<String>>>();
        for (Id currObjId : newObjIdMxCatMappingMap.keySet()) {
            if (isDelete) {
                // query accounts with matching subcategories
                if (oldLeadIds.contains(currObjId)) {
                    joinLeadIdMxCatMappingMap.put(currObjId,CDdVerticalCategoryHelper.getDiffMap(newList,
                                                                                             oldLeadIdMxCatMappingMap.get(currObjId),
                                                                                             currObjId));
                } else if (oldAccountIds.contains(currObjId)) {
                    joinAcctIdMxCatMappingMap.put(currObjId,CDdVerticalCategoryHelper.getDiffMap(newList,
                                                                                             oldAcctIdMxCatMappingMap.get(currObjId),
                                                                                             currObjId));
                }
            } else {
                if (oldLeadIds.contains(currObjId)) {
                    joinLeadIdMxCatMappingMap.put(currObjId,CDdVerticalCategoryHelper.getCombineMap(newObjIdMxCatMappingMap.get(currObjId),
                                                                                                    oldLeadIdMxCatMappingMap.get(currObjId)));
                } else if (oldAccountIds.contains(currObjId)) {
                    joinAcctIdMxCatMappingMap.put(currObjId,CDdVerticalCategoryHelper.getCombineMap(newObjIdMxCatMappingMap.get(currObjId),
                                                                                                    oldAcctIdMxCatMappingMap.get(currObjId)));
                }
            }
        }



        // 5&6 Create list of Accounts with new vertical categories to update
        // TODO don't update accounts that dont need to (if value is same as before)
        List<Account> acctsToUpdate = new List<Account>();
        for (Id currAcctId : joinAcctIdMxCatMappingMap.keySet()) {
            acctsToUpdate.add(new Account(Id = currAcctId,
                                          Merchant_Categories__c = CDdVerticalCategoryHelper.parseMxCategoryMap(joinAcctIdMxCatMappingMap.get(currAcctId))
                              ));
        }

        if (!acctsToUpdate.isEmpty()) {
            setAccountMerchantCategoriesv2_triggered = true;
            update acctsToUpdate;
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        for (Id currLeadId : joinLeadIdMxCatMappingMap.keySet()) {
            leadsToUpdate.add(new Lead(Id = currLeadId,
                                          Merchant_Categories__c = CDdVerticalCategoryHelper.parseMxCategoryMap(joinLeadIdMxCatMappingMap.get(currLeadId))
                              ));
        }

        if (!leadsToUpdate.isEmpty()) {
            setAccountMerchantCategoriesv2_triggered = true;
            update leadsToUpdate;
        }
    }
    
    /** 
    * TODO Move method to CDdVerticalCategoryHelper
    **/
    public static String getCategoryNameForMxCatId(Id MxCatId) {
        if (MxCatIdSettingMap.containsKey(MxCatId)) {
            return MxCatIdSettingMap.get(MxCatId).Name;
        }
        return '';
    }
}