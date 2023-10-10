/**
* @author: Critical River
* @date: 2023-05
* @description Service class for ContentVersion (Mx Document).
*/
public class CDdMxDocumentService {

    private static final String DELIMETER = '#';
    private static final String CASE_STATUS_CLOSED = 'Closed';
    private static final String CASE_STATUS_DEAD = 'Dead';
    private static final String MX_DOCUMENT_LIBRARY = Label.Mx_Document_Library_Name;

    /**
     *This method associates contentdocumentId to contentversion if the file already exists.
     * @param List<ContentVersion>
     */
    public static void associateContentDocument(List<ContentVersion> mxContentVersionList){

        if(mxContentVersionList.isEmpty()) {
            return;
        }

        Map<String,ContentVersion> existingContentVersions = getExistingContentVersions(mxContentVersionList);
        for(ContentVersion mxContentVersion:mxContentVersionList){
            String contentVersionKey = mxContentVersion.Mx_Store_Id__c+DELIMETER+mxContentVersion.Mx_Document_Type__c;
            if(existingContentVersions.containsKey(contentVersionKey)){
                mxContentVersion.ContentDocumentId = existingContentVersions.get(contentVersionKey).ContentDocumentId;
            }
        }
    }

    /**
     * Thismethod moves newly created contentversion documents into corresponding store folder
     * @param List<ContentVersion>
     */
    public static void addMxDocumentToLibrary(List<ContentVersion> newList){
        if(newList.isEmpty()) {
            return;
        }

        Set<Id> newContentDocumentIds = new Set<Id>();
        Set<String> storeIds = new Set<String>();
        Map<Id,String> contentDoc2StoreMap = new Map<Id,String>();
        List<ContentVersion> mxContentVersionList = new List<ContentVersion>();
        List<ContentVersion> mxContVersionDocEventList = new List<ContentVersion>();

        for(ContentVersion contVersion:newList){
            mxContVersionDocEventList.add(contVersion);

            if(contVersion.VersionNumber == '1'){
                newContentDocumentIds.add(contVersion.ContentDocumentId);
                storeIds.add(contVersion.Mx_Store_Id__c);
                contentDoc2StoreMap.put(contVersion.ContentDocumentId,contVersion.Mx_Store_Id__c);
                mxContentVersionList.add(contVersion);
            }
        }

        //Insert entry into Mx_Document_Event__c
        CDdMxDocumentEventService.insertMxDocumentUploadEvents(mxContVersionDocEventList);

        if(mxContentVersionList.isEmpty()) {
            return;
        }


        ContentWorkspace contentLibrary = getMxDocumentLibrary();
        ContentFolder rootFolder = getMxDocumentContentFolder(contentLibrary);
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();

        //Link document to library
        for(Id newDocumentId : newContentDocumentIds){
            contentDocumentLinks.add(getContentDocumentLink(newDocumentId,contentLibrary.Id));
        }

        //Link document to Account
        List<ContentDocumentLink> accountContentDocumentLinks = getAccountContentDocumentLink(newContentDocumentIds,storeIds,contentDoc2StoreMap);
        contentDocumentLinks.addAll(accountContentDocumentLinks);

        //Link document to Case
        List<ContentDocumentLink> caseContentDocumentLinks = getCaseContentDocumentLink(newContentDocumentIds,storeIds,contentDoc2StoreMap);
        contentDocumentLinks.addAll(caseContentDocumentLinks);

        Database.SaveResult[] insertResults = Database.insert(contentDocumentLinks,false);

        //BZAP-21050- Removed store folder creation and moving files in root folder to store folder code

        //Add content type to Mx_Document_Type__c
        addDocumentType(mxContentVersionList);

    }


    public static ContentWorkspace getMxDocumentLibrary() {
        return [SELECT Id FROM ContentWorkspace WHERE Name = :MX_DOCUMENT_LIBRARY];
    }

    public static ContentFolder getMxDocumentContentFolder(ContentWorkspace library) {
        return [SELECT Id FROM ContentFolder WHERE Name = :library.Id];
    }

    public static void checkMxDocumentContentFolder(ContentWorkspace library) {

        List<ContentFolder> contentFolders = [SELECT Id FROM ContentFolder WHERE Name = :library.Id];
        if(contentFolders == null || contentFolders.isEmpty()){
            ContentFolder contentFolder = new ContentFolder();
            contentFolder.Name = library.Id;
            insert contentFolder;
        }
    }

    /**
     * @description  This method returns existing contentversions for the store and documnettype being uploaded.
     * @param List<ContentVersion>
     */
    private static Map<String,ContentVersion> getExistingContentVersions(List<ContentVersion> mxContentVersionList){
        List<String> mxDocumentTypes = new List<String>();
        List<String> mxStoreIds = new List<String>();
        Map<String,ContentVersion> existingContentVersions = new Map<String,ContentVersion>();

        for(ContentVersion contVersion:mxContentVersionList){
            if(contVersion.Mx_Document_Type__c != null && contVersion.Mx_Store_Id__c != null){
                mxDocumentTypes.add(contVersion.Mx_Document_Type__c);
                mxStoreIds.add(contVersion.Mx_Store_Id__c);
            }
        }

        for(ContentVersion existingContentVersion : [SELECT Id,ContentDocumentId,Mx_Document_Type__c,Mx_Store_Id__c FROM ContentVersion
                                        WHERE Mx_Document_Type__c IN :mxDocumentTypes AND Mx_Store_Id__c IN :mxStoreIds]){
            existingContentVersions.put(existingContentVersion.Mx_Store_Id__c+DELIMETER+existingContentVersion.Mx_Document_Type__c,existingContentVersion);
        }

        return existingContentVersions;

    }

    /**
     * @description returns contentdocumentlink list to link files uploaded to Account.
     * @param Set<Id>
     * @param Set<String>
     * @param Map<Id,String>
     */
    private static List<ContentDocumentLink> getAccountContentDocumentLink(Set<Id> newContentDocumentIds,Set<String> storeIds,Map<Id,String> contentDoc2StoreMap){
        List<ContentDocumentLink> accountContentDocumentLinks = new List<ContentDocumentLink>();
        Map<String,Account> storeIdAccountMap = new Map<String,Account>();
        for(Account storeAccount : [SELECT Id,Restaurant_ID__c FROM Account WHERE Restaurant_ID__c IN :storeIds]){
            storeIdAccountMap.put(storeAccount.Restaurant_ID__c,storeAccount);
        }

        for(Id newDocumentId : newContentDocumentIds){
            Account storeAccount = storeIdAccountMap.get(contentDoc2StoreMap.get(newDocumentId));
            if(storeAccount != null){
                accountContentDocumentLinks.add(getContentDocumentLink(newDocumentId,storeAccount.Id));
            }
        }
        return accountContentDocumentLinks;
    }

    /**
     * @description returns contentdocumentlink list to link files uploaded to case.
     * @param Set<Id>
     * @param Set<String>
     * @param Map<Id,String>
     */
    private static List<ContentDocumentLink> getCaseContentDocumentLink(Set<Id> newContentDocumentIds,Set<String> storeIds,Map<Id,String> contentDoc2StoreMap){
        List<ContentDocumentLink> caseContentDocumentLinks = new List<ContentDocumentLink>();
        String mpRTId = Schema.SObjectType.Case.getRecordTypeInfosByName()
                               .get('Marketplace Onboarding').getRecordTypeId();

        Map<String,Case> storeIdCaseMap = new Map<String,Case>();
        for(Case storeCase : [SELECT Id,Account.Restaurant_ID__c FROM Case
                                    WHERE STATUS != :CASE_STATUS_CLOSED
                                    AND STATUS != :CASE_STATUS_DEAD
                                    AND RecordTypeId = :mpRTId
                                    AND AccountId IN (SELECT Id FROM Account WHERE Restaurant_ID__c IN :storeIds)
                                    Order by CreatedDate DESC]){
            if(!storeIdCaseMap.containsKey(storeCase.Account.Restaurant_ID__c)){
                storeIdCaseMap.put(storeCase.Account.Restaurant_ID__c,storeCase);
            }
        }

        for(Id newDocumentId : newContentDocumentIds){
            Case storeCase = storeIdCaseMap.get(contentDoc2StoreMap.get(newDocumentId));
            if(storeCase != null){
                caseContentDocumentLinks.add(getContentDocumentLink(newDocumentId,storeCase.Id));
            }
        }
        return caseContentDocumentLinks;
    }

    /**
     * @description Creates ContentDocumentLink instance
     * @param Id
     * @param Id
     */
    private static ContentDocumentLink getContentDocumentLink(Id documentId,Id entityId){
        ContentDocumentLink documentLink = new ContentDocumentLink();
        documentLink.ContentDocumentId = documentId;
        documentLink.LinkedEntityId = entityId;
        documentLink.ShareType = 'I';
        return documentLink;
    }

    /**
     * @description This method adds Document Type into Mx_Document_Type__c object if the it is not available for the country
     * @param List<ContentVersion> collection of new ContentVersion records
     */
    private static void addDocumentType(List<ContentVersion> mxContentVersionList){

        List<String> countryList = new List<String>();
        List<String> docList = new List<String>();

        for(ContentVersion newContentVersion: mxContentVersionList){
            countryList.add(newContentVersion.Mx_Country__c);
            docList.add(newContentVersion.Mx_Document_Type__c );
        }

        Set<String> countryDocumentTypeSet = new Set<String>();
        for(Mx_Document_Type__c documentType: [SELECT Id,Document_Type__c,Country__c FROM Mx_Document_Type__c
                                    WHERE Country__c IN :countryList AND Document_Type__c IN :docList]){
            countryDocumentTypeSet.add(documentType.Country__c+documentType.Document_Type__c);
        }

        List<Mx_Document_Type__c> mxDocumentTypeList = new List<Mx_Document_Type__c>();
        for(ContentVersion newContentVersion: mxContentVersionList){
            if(!countryDocumentTypeSet.contains(newContentVersion.Mx_Country__c+newContentVersion.Mx_Document_Type__c )){
                mxDocumentTypeList.add(new Mx_Document_Type__c(
                    Country__c = newContentVersion.Mx_Country__c,
                    Document_Type__c = newContentVersion.Mx_Document_Type__c
                ));
            }
        }

        Database.SaveResult[] saveResults = Database.insert(mxDocumentTypeList,false);

    }

}