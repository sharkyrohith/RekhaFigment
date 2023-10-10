/**
* @author Ed
* @date 2021-06
* @description BZAP-11027, 11032 Helper class for Vertical Categories
*/
public class CDdVerticalCategoryHelper {
    public static Boolean handleMerchantCategoriesFlag = false;
    // TODO these two booleans below should be a map of booleans (SObjId -> Boolean)
    // there are risks with just just two primitives (booleans) if cross update/deletes are done across different records (havent tested thoroughly)
    public static Boolean updatingPrimaryFlags = false;
    public static Boolean deletingAllMxCatFlag = false;
    public static Boolean handleMxCategoryMergeFlag = false;
    public static String objectType;
    // public static Map<Id, Vertical_Category_Ids__c> vertCatIdSettingMap = new Map<Id, Vertical_Category_Ids__c>();
    public static Map<Id, Vertical_Category_Ids__c> vertCatIdSettingMap = createMxCatIdSettingMap();
    // Set<String> vertCatNames;
    public static Set<String> parentVertCatNames = new Set<String>();
    public static Set<String> subVertCatNames = new Set<String>();
    public static Vertical_Category_Trigger_Setting__c verticalCatFeatureFlags = Vertical_Category_Trigger_Setting__c.getOrgDefaults();
    public static Vertical_Category_Trigger_Setting__c runUpdateMXCategories = Vertical_Category_Trigger_Setting__c.getInstance(UserInfo.getUserId());

    public CDdVerticalCategoryHelper() {
        this(Schema.Merchant_Category__c.sObjectType);
    }

    public CDdVerticalCategoryHelper(Schema.SObjectType sObjectType) {
        if (sObjectType == Schema.Account.sObjectType) {
            objectType = 'account';
        } else if (sObjectType == Schema.Lead.sObjectType) {
            objectType = 'lead';
        }
        vertCatIdSettingMap = createMxCatIdSettingMap();
        parentVertCatNames = getCategoryNames(true);
        subVertCatNames = getCategoryNames(false);
    }

    public static Set<String> getCategoryNames(Boolean isParent) {
        Set<String> vertCatNames = new Set<String>();
        Map<String, Vertical_Category_Ids__c> vertCatMap = Vertical_Category_Ids__c.getAll();
        for (String currName : vertCatMap.keySet()) {
            if (vertCatMap.get(currName).Is_Parent_Category__c && isParent) {
                vertCatNames.add(currName);
            } else if (!vertCatMap.get(currName).Is_Parent_Category__c && !isParent) {
                vertCatNames.add(currName);
            }
        }
        return vertCatNames;
    }

    /**
    * @description Primary method for Account/Lead trigger for Merchant_Categories__c.
    **/
    public void handleMerchantCategories(List<sObject> newList, Map<Id, sObject> oldMap) {
        System.debug(CDdMerchantCategoryTriggerHandler.setAccountMerchantCategoriesv2_triggered);
        System.debug(handleMerchantCategoriesFlag);
        if (CDdMerchantCategoryTriggerHandler.setAccountMerchantCategoriesv2_triggered || handleMerchantCategoriesFlag) return;
        if (verticalCatFeatureFlags.Disable_All__c) return;

        // check error handling framework
        Map<Id, List<Id>> MxCategoryMap = new Map<Id, List<Id>>();
        List<Merchant_Category__c> newMxCategories = new List<Merchant_Category__c>();
        List<Id> deleteMxCategoryAccountIds = new List<Id>();
        List<Merchant_Category__c> deleteMxCategories = new List<Merchant_Category__c>();
		SObject currOldObj;
        Set<Id> accountPrimaryIdSet = new Set<Id>();
        String oldVertCat;
        String newVertCat;
        String newPrimaryCategory;
        String oldPrimaryCategory;
        List<RecordWithOldAndNewVerticalCategories> recordIdsWithCategoriesList = new List<RecordWithOldAndNewVerticalCategories>();

        for (SObject currNewObj : newList) {
            newVertCat = (String) currNewObj.get('Merchant_Categories__c');
            newPrimaryCategory = (String) currNewObj.get('Primary_Merchant_Category__c');

            if (newVertCat != null) {
                if ((!String.isBlank(newPrimaryCategory) && !parentVertCatNames.contains(newPrimaryCategory.trim())) &&
                    !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                    currNewObj.addError(Label.VC_PrimaryCategory_Name_Validation);
                    continue;
                }


                if (oldMap == null) {
                    // insert new mx categories
                	MxCategoryMap = parseMerchantCategoryValues(newVertCat);
                	newMxCategories.addAll(createMerchantCategories(MxCategoryMap, currNewObj));
                    continue;
                } else {
                    // update, can be both insert/delete
                    currOldObj = oldMap.get(currNewObj.Id);
                    newVertCat = (String) currNewObj.get('Merchant_Categories__c');
                    oldVertCat = (String) currOldObj.get('Merchant_Categories__c');

                    // Account update from lead convert
                    if (CDdLeadTriggerHelper.isLeadVerticalCategoryConvert) {
                        oldPrimaryCategory = (String) currOldObj.get('Primary_Merchant_Category__c');
                        if (!String.isBlank(oldPrimaryCategory)) {
                            if (objectType == 'account') currNewObj.put(Schema.Account.Primary_Merchant_Category__c, oldPrimaryCategory);
                        }
                        newVertCat = CDdVerticalCategoryHelper.getCombineVertCatString(newVertCat, oldVertCat);
                        newMxCategories.addAll(updateMerchantCategoryInserts(newVertCat,
                                                                             oldVertCat,
                                                                             currNewObj.Id));
                        handleMerchantCategoriesFlag = true;
                    } else if (newVertCat != oldVertCat) {
                        newMxCategories.addAll(updateMerchantCategoryInserts(newVertCat,
                                                                             oldVertCat,
                                                                             currNewObj.Id));
                        RecordWithOldAndNewVerticalCategories wrapper = new RecordWithOldAndNewVerticalCategories();
                        wrapper.recordId = currNewObj.Id;
                        wrapper.newVerticalCategories = newVertCat;
                        wrapper.oldVerticalCategories = oldVertCat;
                        recordIdsWithCategoriesList.add(wrapper);
                    }
                }

                if ((String.isBlank(newPrimaryCategory) || !newVertCat.contains(newPrimaryCategory.trim())) &&
                    !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                    currNewObj.addError(Label.VC_PrimaryCategory_Validation +  ': \'' + newPrimaryCategory + '\'');
                }

                try {
                    if (objectType == 'account') currNewObj.put(Schema.Account.Merchant_Categories__c, sortVertCategories(newVertCat));
                    if (objectType == 'lead') currNewObj.put(Schema.Lead.Merchant_Categories__c, sortVertCategories(newVertCat));
                } catch (InvalidVerticalCategoryException e) {
                    currNewObj.addError(e);
                } catch (Exception e) {
                    currNewObj.addError('Something went wrong! Please contact an administrator: ' + e);
                }

            } else if (oldMap != null) {
                if (newPrimaryCategory != null && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                    currNewObj.addError(Label.VC_PrimaryCategory_Validation);
                    continue;
                }

                // delete all mx categories
                currOldObj = oldMap.get(currNewObj.Id);
                oldVertCat = (String) currOldObj.get('Merchant_Categories__c');
                if (oldVertCat != null) {
                    if (objectType == 'account') currNewObj.put(Schema.Account.Primary_Merchant_Category__c, '');
                    if (objectType == 'lead') currNewObj.put(Schema.Lead.Primary_Merchant_Category__c, '');

                    deleteMxCategoryAccountIds.add(currOldObj.Id);
                }
            }
        }

        if (newMxCategories.size() > 0) {
            handleMerchantCategoriesFlag = true;
            insert newMxCategories;
        }

        if (deleteMxCategoryAccountIds.size() > 0) {
            deleteMxCategories.addAll(getMerchantCategories(deleteMxCategoryAccountIds));
        }

        if(!recordIdsWithCategoriesList.isEmpty()){
            deleteMxCategories.addAll(updateMerchantCategoryDeletes(recordIdsWithCategoriesList));
            if (!deleteMxCategories.isEmpty()) {
                deletingAllMxCatFlag = true;
                handleMerchantCategoriesFlag = true;
                delete deleteMxCategories;
            }
        }
    }

    /**
    * @description Trigger for Account/Lead Primary_Merchant_Category__c, updates list of Merchant Category Objects's primary flag
    **/
    public void handlePrimaryCategoryUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        if (verticalCatFeatureFlags.Disable_All__c) return;
        Map<Id, String> newObjIdToPrimaryCatMap = new Map<Id, String>();
        Map<Id, String> oldObjIdToPrimaryCatMap = new Map<Id, String>();
        List<Merchant_Category__c> mxPrimaryCategories = new List<Merchant_Category__c>();
        List<Merchant_Category__c> updateList = new List<Merchant_Category__c>();
        String oldVertCat;
        String newPrimaryVertCat;
        String oldPrimaryVertCat;
        String newVerticalCategories;
        String oldVerticalCategories;

        for (SObject newObj : newList) {
            newPrimaryVertCat = (String) newObj.get('Primary_Merchant_Category__c');
            oldPrimaryVertCat = (String) oldMap.get(newObj.Id).get('Primary_Merchant_Category__c');
            newVerticalCategories = (String) newObj.get('Merchant_Categories__c');
            oldVerticalCategories = (String) newObj.get('Merchant_Categories__c');

            if (newPrimaryVertCat != null && newPrimaryVertCat != oldPrimaryVertCat) {
                if (newVerticalCategories != null) {
                    if (!parentVertCatNames.contains(newPrimaryVertCat.trim()) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                        newObj.addError(Label.VC_PrimaryCategory_Name_Validation);
                        continue;
                    }
                    if (!newVerticalCategories.contains(newPrimaryVertCat.trim()) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                        newObj.addError(Label.VC_PrimaryCategory_Validation  + ': \'' +  newPrimaryVertCat + '\'');
                        continue;
                    }
                }

                newObjIdToPrimaryCatMap.put(newObj.Id, newPrimaryVertCat);
                oldObjIdToPrimaryCatMap.put(newObj.Id, oldPrimaryVertCat);
            } else if (String.isBlank(newPrimaryVertCat) && newPrimaryVertCat != oldPrimaryVertCat) {
                if (!String.isBlank(newVerticalCategories) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                    newObj.addError(Label.VC_Primary_Validation);
                    continue;
                }
            }
        }

        String newCatName;
        String oldCatName;
        String verticalCatName;

        if (!newObjIdToPrimaryCatMap.isEmpty()) {
            if (objectType == 'account') {
                mxPrimaryCategories = [SELECT Id, Account__c, Vertical_Category__c, Primary__c
                                       FROM Merchant_Category__c
                                       WHERE Account__c in :newObjIdToPrimaryCatMap.keySet()];
            } else if (objectType == 'lead') {
                mxPrimaryCategories = [SELECT Id, Lead__c, Vertical_Category__c, Primary__c
                                       FROM Merchant_Category__c
                                       WHERE Lead__c in :newObjIdToPrimaryCatMap.keySet()];
            }

            for (Merchant_Category__c currMxCat : mxPrimaryCategories) {
                if (objectType == 'account') {
                    newCatName = newObjIdToPrimaryCatMap.get(currMxCat.Account__c);
                    oldCatName = oldObjIdToPrimaryCatMap.get(currMxCat.Account__c);
                } else if (objectType == 'lead') {
                    newCatName = newObjIdToPrimaryCatMap.get(currMxCat.Lead__c);
                    oldCatName = oldObjIdToPrimaryCatMap.get(currMxCat.Lead__c);
                }
                verticalCatName = getCategoryNameForMxCatId(currMxCat.Vertical_Category__c);
                if (!String.isBlank(verticalCatName) && !String.isBlank(newCatName) && verticalCatName == newCatName && currMxCat.Primary__c == false) {
                    updateList.add(new Merchant_Category__c(Id = currMxCat.Id, Primary__c = true));
                } else if (!String.isBlank(verticalCatName) && !String.isBlank(oldCatName) && verticalCatName == oldCatName && currMxCat.Primary__c == true) {
                    updateList.add(new Merchant_Category__c(Id = currMxCat.Id, Primary__c = false));
                }
            }
        }
        if (updateList.size() > 0) {
            updatingPrimaryFlags = true;
            update updateList;
        }
    }

    /**
    * @description Parses Merchant_Categories__c and returns a Map of (CategoryIds, List SubCategoryIds)
    * Example Input 'Alcohol / Alcohol-Lite; Prepared Food & Drink (Rx) / Bakery / Ice Cream / Drinks'
    * Example Output {CategoryID1=(subCategoryID1, subCategoryID2, subCategoryID3), CategoryID2=(subCategoryID4)}
    **/
    public static Map<Id, List<Id>> parseMerchantCategoryValues(String mxCategoryList) {
        Map<Id, List<Id>> MxCategoryMap = new Map<Id, List<Id>>();

        if (String.isBlank(mxCategoryList)) return MxCategoryMap;
        // error handling
        // return map of mx category

        List<String> categoryList = mxCategoryList.split(';');
        for (String currCategory : categoryList) {
            currCategory = currCategory.trim();
            String mainCategory = currCategory.substringBefore('/').trim();
            String subCategories = currCategory.subStringAfter('/');


            Vertical_Category_Ids__c catSettings = Vertical_Category_Ids__c.getValues(mainCategory);
            if (catSettings == null) continue;
            List<Id> subCategoryList = new List<Id>();
            MxCategoryMap.put(catSettings.Id__c, subCategoryList);
            for (String currSubCategory : subCategories.split('/')) {
                currSubCategory = currSubCategory.trim();
                Vertical_Category_Ids__c subCatSettings = Vertical_Category_Ids__c.getValues(currSubCategory);
                if (subCatSettings != null && subCatSettings.Parent_Category__c != null && subCatSettings.Parent_Category__c == catSettings.Name) {
                    subCategoryList.add(subCatSettings.Id__c);
                    MxCategoryMap.put((Id) catSettings.Id__c, subCategoryList);
                }
            }
        }

        return MxCategoryMap;
    }

    /**
    * @description Parses Map of (CategoryIds,List<SubCategoryIds>) and returns list of Merchant_Category__c to insert
    *              Also sets the primary flag if necessary
    * Example Input {CategoryID1=(subCategoryID1, subCategoryID2, subCategoryID3), CategoryID2=(subCategoryID4)}
    * Example Output List<Merchant_Category> - 1 for each category+subcategory
    **/
    public static List<Merchant_Category__c> createMerchantCategories(Map<Id, List<Id>> MxCategoryMap, SObject sObj) {
        if (objectType != String.valueOf(sObj.getSobjectType()).toLowerCase()) return null;

        List<Id> subCategoryIds = new List<Id>();
        List<Merchant_Category__c> newMxCategories = new List<Merchant_Category__c>();
        Merchant_Category__c currMxCategory;
        String primaryVertCat;

        for (Id categoryId : MxCategoryMap.keySet()) {
            // Set primary flag on Account insert
            primaryVertCat = (String) sObj.get('Primary_Merchant_Category__c');
            if (!String.isBlank(primaryVertCat) && primaryVertCat == getCategoryNameForMxCatId(categoryId)) {
                currMxCategory = new Merchant_Category__c(Vertical_Category__c = categoryId, Primary__c = true);
                updatingPrimaryFlags = true;
                if (objectType == 'account') currMxCategory.Account__c = sObj.Id;
                if (objectType == 'lead') currMxCategory.Lead__c = sObj.Id;

                newMxCategories.add(currMxCategory);
            } else {
                currMxCategory = new Merchant_Category__c(Vertical_Category__c = categoryId);
                if (objectType == 'account') currMxCategory.Account__c = sObj.Id;
                if (objectType == 'lead') currMxCategory.Lead__c = sObj.Id;

                newMxCategories.add(currMxCategory);
            }

            subCategoryIds = MxCategoryMap.get(categoryId);
            for (Id subCategoryId : subCategoryIds) {
                currMxCategory = new Merchant_Category__c(Vertical_Category__c = subCategoryId);
                if (objectType == 'account') currMxCategory.Account__c = sObj.Id;
                if (objectType == 'lead') currMxCategory.Lead__c = sObj.Id;

                newMxCategories.add(currMxCategory);
            }
        }

        return newMxCategories;
    }

    /**
    * @description Parse old and new Merchant_Categories__c, and returns list of Merchant Category objects to insert. Also requires SObjectId
    * Example Input oldMxCatList = 'Prepared Food & Drink (Rx) / Bakery ; Grocery'
    *               newMxCatList = 'Prepared Food & Drink (Rx) / Bakery / Ice Cream; Grocery'
    * Example Output List<Merchant_Category> where Vertical Category = 'Ice Cream'
    **/
    public static List<Merchant_Category__c> updateMerchantCategoryInserts(String newMxCatList, String oldMxCatList, Id sObjectId) {
        Map<Id, List<Id>> newMxCatMap = parseMerchantCategoryValues(newMxCatList);
        Map<Id, List<Id>> oldMxCatMap = parseMerchantCategoryValues(oldMxCatList);

        List<Merchant_Category__c> insertList = new List<Merchant_Category__c>();
        for (Id primaryCategoryId : newMxCatMap.keySet()) {
            if (oldMxCatMap.containsKey(primaryCategoryId)) {
                for (Id subCategoryId : newMxCatMap.get(primaryCategoryId)) {
                    if (!oldMxCatMap.get(primaryCategoryId).contains(subCategoryId)) {
                        if (objectType == 'account') insertList.add(new Merchant_Category__c(Account__c = sObjectId, Vertical_Category__c = subCategoryId));
                        if (objectType == 'lead') insertList.add(new Merchant_Category__c(Lead__c = sObjectId, Vertical_Category__c = subCategoryId));
                    }
                }
            } else {
                if (objectType == 'account') insertList.add(new Merchant_Category__c(Account__c = sObjectId, Vertical_Category__c = primaryCategoryId));
                if (objectType == 'lead') insertList.add(new Merchant_Category__c(Lead__c = sObjectId, Vertical_Category__c = primaryCategoryId));

                for (Id subCategoryId : newMxCatMap.get(primaryCategoryId)) {
                    if (objectType == 'account') insertList.add(new Merchant_Category__c(Account__c = sObjectId, Vertical_Category__c = subCategoryId));
                    if (objectType == 'lead') insertList.add(new Merchant_Category__c(Lead__c = sObjectId, Vertical_Category__c = subCategoryId));
                }

            }
        }
        return insertList;
    }

    /**
    * @description Parse old and new Merchant_Categories__c, and returns list of Merchant Category objects to delete. Also requires SObjectId
    * Example Input oldMxCatList = 'Prepared Food & Drink (Rx) / Bakery / Ice Cream ; Grocery'
    *               newMxCatList = 'Prepared Food & Drink (Rx) / Bakery ; Grocery'
    * Example Output List<Merchant_Category>, where Vertical Category = 'Ice Cream'
    **/
    public static List<Merchant_Category__c> updateMerchantCategoryDeletes(List<RecordWithOldAndNewVerticalCategories> recordIdWithCategories) {
        List<Merchant_Category__c> deleteList = new List<Merchant_Category__c>();
        List<String> concatenatedIdStringForDeleteRecords = new List<String>();
        Set<Id> recordIdsSet = new Set<Id>();

        for(RecordWithOldAndNewVerticalCategories wrapper: recordIdWithCategories){
            Map<Id, List<Id>> newMxCatMap = parseMerchantCategoryValues(wrapper.newVerticalCategories);
            Map<Id, List<Id>> oldMxCatMap = parseMerchantCategoryValues(wrapper.oldVerticalCategories);
             // finding inserts
            for (Id oldCategoryId : oldMxCatMap.keySet()) {
                if (newMxCatMap.containsKey(oldCategoryId)) {
                    for (Id subCategoryId : oldMxCatMap.get(oldCategoryId)) {
                        if (!newMxCatMap.get(oldCategoryId).contains(subCategoryId)) {
                            recordIdsSet.add(wrapper.recordId);
                            concatenatedIdStringForDeleteRecords.add(wrapper.recordId+'-'+subCategoryId);
                        }
                    }
                } else {
                    // new ones
                    recordIdsSet.add(wrapper.recordId);
                    concatenatedIdStringForDeleteRecords.add(wrapper.recordId+'-'+oldCategoryId);
                    for (Id subCategoryId : oldMxCatMap.get(oldCategoryId)) {
                        concatenatedIdStringForDeleteRecords.add(wrapper.recordId+'-'+subCategoryId);
                    }

                }
            }
        }
        string deleteQuery = 'SELECT Id FROM Merchant_Category__c WHERE Category_With_Account_Lead__c IN:concatenatedIdStringForDeleteRecords';
        if (objectType == 'account'){
            deleteQuery += ' AND Account__c IN:recordIdsSet';
        } else if (objectType == 'lead') {
            deleteQuery += ' AND Lead__c IN:recordIdsSet';
        }
        deleteList = Database.query(deleteQuery);
        return deleteList;
    }

    /**
    * @description Input list of SObjectIds (Lead/Account), return a list of Merchant Category Objects
    **/
    public static List<Merchant_Category__c> getMerchantCategories(List<Id> sObjectIds) {
        String query;
        if (objectType == 'account') {
            query = 'SELECT Id FROM Merchant_Category__c WHERE Account__c in';
        } else if (objectType == 'lead') {
            query = 'SELECT Id FROM Merchant_Category__c WHERE Lead__c in';
        }


        if (query != null) {
            List<Merchant_Category__c> mxCategoryList = Database.query(query + ' :sObjectIds');
            return mxCategoryList;
        }
        return null;
    }



    /**
    * @description Create custom setting map for Vertical_Category_Ids__c, using ID as key (instead of Name)
    **/
    public static Map<Id, Vertical_Category_Ids__c> createMxCatIdSettingMap() {
        Map<String, Vertical_Category_Ids__c> mxCatSettings = Vertical_Category_Ids__c.getAll();
        Map<Id, Vertical_Category_Ids__c> mxCatSettingsIdMap = new Map<Id, Vertical_Category_Ids__c>();
        for (Vertical_Category_Ids__c currCat : mxCatSettings.values()) {
            mxCatSettingsIdMap.put(currCat.Id__c, currCat);
        }
        return mxCatSettingsIdMap;
    }

    /**
    * @description Combine two maps together, removing dupes
    * TODO rework generics
    **/
    public static Map<String, List<String>> getCombineMap(Map<String, List<String>> newMxCategories, Map<String, List<String>> oldMxCategories) {
        if (oldMxCategories.isEmpty()) {
            return newMxCategories;
        }
        if (newMxCategories.isEmpty()) {
            return oldMxCategories;
        }

        Map<String, List<String>> combineMap = oldMxCategories.clone();
        Set<String> combineCatListSet;
        List<String> oldSubCatList;
        List<String> newSubCatList;
        for (String currNewCat : newMxCategories.keySet()) {
            newSubCatList = newMxCategories.get(currNewCat);
            combineCatListSet = new Set<String>();
            if (combineMap.containsKey(currNewCat)) {
                oldSubCatList = combineMap.get(currNewCat);
                combineCatListSet.addAll(oldSubCatList);
                combineCatListSet.addAll(newSubCatList);
                combineMap.put(currNewCat,new List<String>(combineCatListSet));
            } else {
                combineMap.put(currNewCat, newSubCatList);
            }

        }

        return combineMap;
    }

    /**
    * @description For CurrObjId, remove a list of Merchant Categories (Grocery, Ice Cream, etc.) from oldMxCategories
    * Also async deletes sub categories if a main category is deleted
    **/
    public static Map<String, List<String>> getDiffMap(List<Merchant_Category__c> toDeleteMxCategories, Map<String, List<String>> oldMxCategories, Id currObjId) {
        if (oldMxCategories.isEmpty()) {
            return new Map<String, List<String>>();
        }
        if (toDeleteMxCategories.isEmpty()) {
            return oldMxCategories;
        }

        Map<String, List<String>> combineMap = oldMxCategories;
        List<String> combineCatList;
        Integer deleteIndex;
        String currDeleteCatName;
        Map<String, Vertical_Category_Ids__c> mxCatSettings = Vertical_Category_Ids__c.getAll();
        List<Id> deletedMainCatList = new List<Id>();
        for (Merchant_Category__c currDeleteCat : toDeleteMxCategories) {
            currDeleteCatName = vertCatIdSettingMap.get(currDeleteCat.Vertical_Category__c).Name;
            if (combineMap.containsKey(currDeleteCatName) && (currObjId == currDeleteCat.Account__c || currObjId == currDeleteCat.Lead__c)) {
                // deleting main category, so async delete all subcat junction records;
                combineMap.remove(currDeleteCatName);

                // TODO can check if it has subcategories before doing this, to avoid unnecessary async calls
                deletedMainCatList.add(currDeleteCat.Vertical_Category__c);
            } else {
                String parentKeyForSubCat = vertCatIdSettingMap.get(currDeleteCat.Vertical_Category__c).Parent_Category__c;

                if (!String.isEmpty(parentKeyForSubCat) && combineMap.containsKey(parentKeyForSubCat)) {
                    combineCatList = combineMap.get(parentKeyForSubCat);
                    deleteIndex = combineCatList.indexOf(currDeleteCatName);
                    if (deleteIndex != -1) {
                        combineCatList.remove(deleteIndex);
                    }
                }
            }
        }

        if (!deletedMainCatList.isEmpty() && !verticalCatFeatureFlags.Async_Del_Child_Categories_Is_Disabled__c) {
            System.enqueueJob(new DeleteSubCategoriesQueue(deletedMainCatList, currObjId));
        }
        return combineMap;
    }

    /**
    * @description For CurrObjId, delete all MxCategory records for
                   subcategories (e.g. Alcohol-lite) of a given primary category (e.g. Alcohol)
                   Queueable has higher limits than future, but this can still hit limits because it's in a loop
    **/
    class DeleteSubCategoriesQueue implements Queueable {
        List<Merchant_Category__c> toDeleteSObjs = new List<Merchant_Category__c>();

        DeleteSubCategoriesQueue(List<Id> mainCategories, Id sObjId) {
            // TODO Or Lead__c doesn't work I think
            List<Id> subCategoryList = getSubCategoryList(mainCategories);
            toDeleteSObjs = [SELECT Id
                             FROM Merchant_Category__c
                             WHERE (Account__c = :sObjId OR Lead__c = :sObjId)
                             AND Vertical_Category__c in :subCategoryList];
        }

        public void execute(QueueableContext context) {
            Database.delete(toDeleteSObjs, false);
        }
    }

    public void deleteAllMxCategories(Map<Id, SObject> oldMap) {
        if (verticalCatFeatureFlags.Disable_All__c) return;
        // DELETE ALL JUNC SOBJECTS
        List<Merchant_Category__c> deleteList = new List<Merchant_Category__c>();
        if (objectType == 'account') deleteList = [SELECT Id FROM Merchant_Category__c WHERE Account__c in :oldMap.keySet()];
        if (objectType == 'lead') deleteList = [SELECT Id FROM Merchant_Category__c WHERE Lead__c in :oldMap.keySet()];


        deletingAllMxCatFlag = true;
        handleMerchantCategoriesFlag = true;
        Database.delete(deleteList, false);
    }

    public void handleMxCategoryMerge(List<SObject> oldList) {
        if (verticalCatFeatureFlags.Disable_All__c) return;

        List<SObject> mergeList = new List<SObject>();

        String masterRecordId;
        for (SObject currSObj : oldList) {
            masterRecordId = (String) currSObj.get('MasterRecordId');
            if (String.isNotBlank(MasterRecordId)) {
                mergeList.add(currSObj);
            }
        }


        System.enqueueJob(new VerticalCategoryMerge(mergeList));
    }

    /**
    * @description TODO
    **/
    class VerticalCategoryMerge implements Queueable {
        Map<Id, SObject> parentVertMap = new Map<Id, SObject>();
        List<SObject> mergedSObjects;
        List<SObject> updateSObjects = new List<SObject>();
        SObject queriedParent;
        SObject updateParent;
        String oldVertCat;
        String newVertCat;
        String combineVertCat;
        String masterRecordId;
        Id currId;
        Id parentId;
        List<Merchant_Category__c> deleteList = new List<Merchant_Category__c>();

        VerticalCategoryMerge(List<SObject> mergedSObjects) {
            this.mergedSObjects = mergedSObjects;
        }

        public void execute(QueueableContext context) {
            //Added try catch exception to log errors as part of BZAP-17575
            try{
                for (SObject currSObj : mergedSObjects) {
                    masterRecordId = (String) currSObj.get('MasterRecordId');
                    oldVertCat = (String) currSObj.get('Merchant_Categories__c');
                    currId = (Id) currSObj.get('Id');
                    if (currSObj instanceof Account) {
                        if (parentVertMap.containsKey(MasterRecordId)) {
                            updateParent = parentVertMap.get(MasterRecordId);
                            updateParent.put(Schema.Account.Merchant_Categories__c, sortVertCategories(
                                                                                     getCombineVertCatString(
                                                                                         (String) updateParent.get('Merchant_Categories__c'),
                                                                                         oldVertCat)));
                        } else {
                            queriedParent = [SELECT Id, Merchant_Categories__c FROM Account WHERE Id = :MasterRecordId FOR UPDATE];
                            newVertCat = (String) queriedParent.get('Merchant_Categories__c');

                            combineVertCat = getCombineVertCatString(newVertCat, oldVertCat);
                            if(String.isNotBlank(combineVertCat)){
                                parentVertMap.put(MasterRecordId, new Account(Id = MasterRecordId, Merchant_Categories__c = combineVertCat));
                            }
                        }
                    } else if (currSObj instanceof Lead) {
                        if (parentVertMap.containsKey(MasterRecordId)) {
                            updateParent = parentVertMap.get(MasterRecordId);
                            updateParent.put(Schema.Lead.Merchant_Categories__c, sortVertCategories(
                                                                                     getCombineVertCatString(
                                                                                         (String) updateParent.get('Merchant_Categories__c'),
                                                                                         oldVertCat)));
                        } else {
                            queriedParent = [SELECT Id, Merchant_Categories__c FROM Lead WHERE Id = :MasterRecordId FOR UPDATE];
                            newVertCat = (String) queriedParent.get('Merchant_Categories__c');

                            combineVertCat = getCombineVertCatString(newVertCat, oldVertCat);
                            if(String.isNotBlank(combineVertCat)){
                                parentVertMap.put(MasterRecordId, new Lead(Id = MasterRecordId, Merchant_Categories__c = combineVertCat));
                            }
                        }
                    }
                }

                update parentVertMap.values();
            } catch(Exception e){
                List<String> logMessages = new List<String>();
                String expMessage = e.getMessage();
                for(Id recId :parentVertMap.keyset()){
                    String message = JSON.Serialize(parentVertMap.get(recId))+expMessage;
                    logMessages.add(message);
                }
                CDdErrorUtilities.createApexLogs(logMessages, 'VerticalCategoryMerge', 'execute', logginglevel.ERROR);
            }
        }
    }

    /**
    * @description Return list of Sub Category IDs (Alcohol-Lite) for given Main Category (Alcohol)
    **/
    public static List<Id> getSubCategoryList(List<Id> mainCategories) {
        List<Id> subCategoryList = new List<Id>();
        Map<String, Vertical_Category_Ids__c> mxCatSettings = Vertical_Category_Ids__c.getAll();
        String parentCategoryName = '';
        for (Vertical_Category_Ids__c currCategorySetting : mxCatSettings.values()) {
            if (String.isBlank(currCategorySetting.Parent_Category__c)) {
                continue;
            }
            parentCategoryName = mxCatSettings.get(currCategorySetting.Parent_Category__c).Id__c;
            if (!String.isBlank(parentCategoryName) && mainCategories.contains(parentCategoryName)) {
                subCategoryList.add(currCategorySetting.Id__c);
            }
        }
        return subCategoryList;
    }

    /**
    * @description Return a Map<SObjectId, CategoryMap> where CategoryMap is Map<MainCategory, List<SubCategory>>
                   for an input list of Merchant Categories
    **/
    public static Map<Id, Map<String, List<String>>> generateMxCatMapping(List<Merchant_Category__c> catInputList) {
        Map<Id, Map<String, List<String>>> accountIdToCategoryMap = new Map<Id, Map<String, List<String>>>();
        Map<String, List<String>> categoryMap;
        Id currObjId;
        Vertical_Category_Ids__c currCategorySetting;
        List<String> currCategoryList;
        String currCategoryName;

        for (Merchant_Category__c currMxCat : catInputList) {
            if (currMxCat.Account__c != null && currMxCat.Lead__c == null) {
                currObjId = currMxCat.Account__c;
            } else if (currMxCat.Account__c == null && currMxCat.Lead__c != null) {
                currObjId = currMxCat.Lead__c;
            } else {
                continue;
            }
            currCategorySetting = vertCatIdSettingMap.get(currMxCat.Vertical_Category__c);
            currCategoryName = currCategorySetting.Name;

            if (!accountIdToCategoryMap.containsKey(currObjId)) {
                categoryMap = new Map<String, List<String>>();
                if (currCategorySetting.Is_Parent_Category__c) {
                    categoryMap.put(currCategoryName, new List<String>());
                } else {
                    currCategoryList = new List<String> { currCategoryName };
                    categoryMap.put(currCategorySetting.Parent_Category__c, currCategoryList);
                }
                accountIdToCategoryMap.put(currObjId, categoryMap);
            } else {
                categoryMap = accountIdToCategoryMap.get(currObjId);
                if (currCategorySetting.Is_Parent_Category__c) {
                    if (!categoryMap.containsKey(currCategoryName)) {
                        categoryMap.put(currCategoryName, new List<String>());
                    }
                } else {
                    if (categoryMap.containsKey(currCategorySetting.Parent_Category__c)) {
                        currCategoryList = categoryMap.get(currCategorySetting.Parent_Category__c);
                        currCategoryList.add(currCategoryName);
                    }
                }
            }
        }
        return accountIdToCategoryMap;
    }

    /**
    * @description For input MxCategoryMap w/ IDs, return as a String map (using custom setting)
    **/
    public static Map<String, List<String>> convertIdMapToNameMap(Map<Id, List<Id>> mxCatIdMap) {
        Map<String, List<String>> MxCatNameMap = new Map<String, List<String>>();
        List<String> subCatList;
        String currCatName;

        for (Id currCatId : mxCatIdMap.keySet()) {
            subCatList = new List<String>();
            currCatName = vertCatIdSettingMap.get(currCatId).Name;

            for (Id currSubCatId: mxCatIdMap.get(currCatId)){
                subCatList.add(vertCatIdSettingMap.get(currSubCatId).Name);
            }
            MxCatNameMap.put(currCatName,subCatList);
        }

        return MxCatNameMap;
    }

    /**
    * @description For input MxCategoryMap w/ Strings, return a valid Merchant_Categories__c value
    **/
    public static String parseMxCategoryMap(Map<String, List<String>> mxCategoryMap) {
        if (mxCategoryMap.isEmpty()) return '';

        String categoryList = '';
        List<String> mapKeyList = new List<String>(mxCategoryMap.keySet());
        List<String> subCategories = new List<String>();

        mapKeyList.sort();
        for (String currMainCategory : mapKeyList) {
            categoryList += currMainCategory;

            if (!mxCategoryMap.get(currMainCategory).isEmpty()) {
                categoryList += ' / ';
                subCategories = mxCategoryMap.get(currMainCategory);
                subCategories.sort();
                for (String currSubCategory : subCategories) {
                    categoryList += currSubCategory + ' / ';
                }
                categoryList = categoryList.substring(0,categoryList.length()-3);
            }
            categoryList += ' ; ';
        }
        categoryList = categoryList.substring(0,categoryList.length()-3);
        return categoryList;
    }

    /**
    * @description Combine Vertical Category String, remove dupes
    **/
    public static String getCombineVertCatString(String oldInput, String newInput) {
        if (String.isBlank(oldInput) && String.isBlank(newInput)) return '';
        if (String.isBlank(oldInput)) return newInput;
        if (String.isBlank(newInput)) return oldInput;
        String s = '';

        Map<String, List<String>> oldMap = convertIdMapToNameMap(parseMerchantCategoryValues(oldInput));
        Map<String, List<String>> newMap = convertIdMapToNameMap(parseMerchantCategoryValues(newInput));

        return parseMxCategoryMap(getCombineMap(oldMap, newMap));
    }

    /**
    * @description For input MerchantCategory Setting ID, return the Name
    * Input Salesforce Custom ID
    * Return 'Ice Cream'
    **/
    public static String getCategoryNameForMxCatId(Id MxCatId) {
        if (!vertCatIdSettingMap.containsKey(MxCatId)) return '';
        return vertCatIdSettingMap.get(MxCatId).Name;
    }

    /**
    * @description Sort (alphabetize) Merchant_Categories__c value
    **/

    public static String sortVertCategories(String inputString) {
        if (verticalCatFeatureFlags.Name_Sort_And_Validate_Is_Disabled__c) return inputString;

        Set<String> parentVertCatNames = getCategoryNames(true);
        Set<String> subVertCatNames = getCategoryNames(false);
        List<String> finalString = new List<String>();
        List<String> currCategories = new List<String>();
        String currParentCategory;


        List<String> parentCategories = inputString.trim().split('\\s*;\\s*');
        parentCategories.sort();

        // currParentCategory is Prepared Food & Drink (Rx) / Bakery / Ice Cream / Drinks
        for (String currCategory : parentCategories) {
            currCategories = currCategory.trim().split('\\s*/\\s*');
            // Can enforce check cat check here
            // if (!parentVertCatNames.contains(currParentCategory))
            currParentCategory = currCategories.remove(0);
            if (!parentVertCatNames.contains(currParentCategory) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                throw new InvalidVerticalCategoryException(String.format(Label.VC_InvalidParentCategory_Validation, new List<String>{currParentCategory}));
            }
            currCategories.sort();


            for (String currSubCategory : currCategories) {
                if (!subVertCatNames.contains(currSubCategory) && !verticalCatFeatureFlags.All_Validation_Is_Disabled__c) {
                    throw new InvalidVerticalCategoryException(String.format(Label.VC_InvalidChildCategory_Validation, new List<String>{currSubCategory}));
                }
            }


            if (currCategories.size() > 0) {
                finalString.add(currParentCategory + ' / ' + String.join(currCategories, ' / '));
            } else {
                finalString.add(currParentCategory);
            }
        }
        return String.join(finalString, ' ; ');
    }

    /**
     * @author Swedhaa Sri M
     * @date 05/2022
     * @description: BASD-29431 Update Merchant Categories based on Primary Merchant Category on Lead and Account
     * This method will only run when Vertical Category Trigger Setting.Run_Update_Merchant_Categories_method__c is set to true
     */

    public void updateHubspotMerchantCategories(List<sObject> newList, Map<Id, sObject> oldMap){

        if (!runUpdateMXCategories.Run_Update_Merchant_Categories_method__c) {
            return;
        }

        List<sObject> objsToUpdate = new List<sObject>();
        String MXCategoryToAppend;
        String merchantCat = 'Merchant_Categories__c';
        String newPrimaryCategory = 'Primary_Merchant_Category__c';

        for(sObject currObj : newList){
            if(oldMap == null || currObj.get(newPrimaryCategory) != oldMap.get(currObj.Id).get(newPrimaryCategory)){

                if(currObj.get(newPrimaryCategory) != null && currObj.get(merchantCat) == null){

                   currObj.put(merchantCat, currObj.get(newPrimaryCategory));
                   objsToUpdate.add(currObj);
                }
                else if (currObj.get(newPrimaryCategory) != null && currObj.get(merchantCat) != null){
                    String merchantCatValue = (String)currObj.get(merchantCat);
                    if(merchantCatValue.contains((String)currObj.get(newPrimaryCategory))){
                        return;
                    }
                    else{
                        MXCategoryToAppend = currObj.get(merchantCat) + ';'+ currObj.get(newPrimaryCategory);
                        currObj.put(merchantCat, MXCategoryToAppend);
                        objsToUpdate.add(currObj);
                    }
                }
            }
        }
    }

    /**
     * @author Ila Maheshwari
     * @date 10/2022
     * @description: BASD-29430 Keep Primary_Merchant_Categories__c and Primary_Merchant_Category__c field value in sync
     */
    public void syncPrimaryMerchantCategoryFields(List<sObject> newList, Map<Id, sObject> oldMap){

        if (!verticalCatFeatureFlags.Run_Sync_Primary_Merchant_Cat_Fields__c) {
            return;
        }

        Boolean isInsert = (oldMap == null) ? true : false;
        String primaryMerCategories = 'Primary_Merchant_Categories__c';
        String primaryMerCategory = 'Primary_Merchant_Category__c';

        for (sObject currObj : newList) {
            String newPrimaryMerCategories = (String)currObj.get('Primary_Merchant_Categories__c');
            String newPrimaryMerCategory = (String)currObj.get('Primary_Merchant_Category__c');

            if (((isInsert && newPrimaryMerCategory == null) || (oldMap != null && currObj.get(primaryMerCategories) != oldMap.get(currObj.Id).get(primaryMerCategories)
            && newPrimaryMerCategory == oldMap.get(currObj.Id).get(primaryMerCategory))) && newPrimaryMerCategory != newPrimaryMerCategories) {
                    currObj.put(primaryMerCategory, newPrimaryMerCategories);
                }
            else if ((isInsert || (oldMap != null && newPrimaryMerCategory != oldMap.get(currObj.Id).get(primaryMerCategory))
                      && newPrimaryMerCategory != newPrimaryMerCategories)) {
                          currObj.put(primaryMerCategories, newPrimaryMerCategory);
                }
        }
    }

    public class InvalidVerticalCategoryException extends Exception {}

    public class RecordWithOldAndNewVerticalCategories{
        public Id recordId;
        public String newVerticalCategories;
        public String oldVerticalCategories;
    }

}