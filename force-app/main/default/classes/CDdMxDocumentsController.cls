public without sharing class CDdMxDocumentsController {

    @AuraEnabled(Cacheable = true)
    public static MasterDataWrapper getMasterData(Id recordIdCase) {

        MasterDataWrapper objMasterDataWrapper = new MasterDataWrapper();

        Map<String,List<String>> mapStatusToStatusReason = new Map<String,List<String>>();

        try {

            List<Case> lstCase = [SELECT id, Account.Restaurant_ID__c, Account.Name, Account.BillingCountryCode
                                    FROM Case where Id =: recordIdCase ];

            String countryCode;
            if(!lstCase.isEmpty() && lstCase[0].Account.BillingCountryCode != null){

               countryCode = lstCase[0].Account.BillingCountryCode;
            }

            for(Mx_Business_Verification_Status_Reason__c objStatus : [SELECT id, Status__c, Status_Reason__c
                                                                        FROM Mx_Business_Verification_Status_Reason__c
                                                                        Order by Status__c, Status_Reason__c]){

                if(!mapStatusToStatusReason.containsKey(objStatus.Status__c)){
                    mapStatusToStatusReason.put(objStatus.Status__c,new List<String>());
                }
                mapStatusToStatusReason.get(objStatus.Status__c).add(objStatus.Status_Reason__c);
            }

            objMasterDataWrapper.mapStatusToStatusReason =  mapStatusToStatusReason;

            List<String> lstDocTypeName = new List<String>();
            for(Mx_Document_Type__c objDocType : [SELECT Name, Country__c, Document_Type__c
                                                        FROM Mx_Document_Type__c WHERE Country__c=:countryCode
                                                        Order By Document_Type__c]){

                lstDocTypeName.add(objDocType.Document_Type__c);
            }
            objMasterDataWrapper.lstDocTypeName =  lstDocTypeName;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return objMasterDataWrapper;
    }

    @AuraEnabled(Cacheable = false)
    public static DataWrapper getData(Id recordIdCase) {

        try {
            DataWrapper objDataWrapper = new DataWrapper();
            List<Case> lstCase = [SELECT id, Account.Restaurant_ID__c, Account.Name FROM Case where Id =: recordIdCase ];

            String strStoreId;
            if(!lstCase.isEmpty() && lstCase[0].account.Restaurant_ID__c != null){

               strStoreId = lstCase[0].account.Restaurant_ID__c;
            }

            if(string.isBlank(strStoreId)){
                return null;
            }

            List<Mx_Onboarding__c> lstOnboarding = [SELECT Id, Business_Verification_Status__c,
                                                            Business_Verification_Status_Reason__c,
                                                            Business_Verification_Status_Notes__c
                                                            FROM Mx_Onboarding__c WHERE StoreId__c =: strStoreId];

            if(lstOnboarding == null || lstOnboarding.isEmpty()){
                return null;
            }

            if(!lstOnboarding.isEmpty()){
                objDataWrapper.Status = lstOnboarding[0].Business_Verification_Status__c;
                objDataWrapper.StatusReason = lstOnboarding[0].Business_Verification_Status_Reason__c;
                objDataWrapper.StatusNotes = lstOnboarding[0].Business_Verification_Status_Notes__c;
                objDataWrapper.businessVerificationId = lstOnboarding[0].Id;
            }

            List<ContentVersion> returnFiles = new List<ContentVersion>();
            Set<string> docTypesDups = new Set<string>();
            for(ContentVersion cv:[SELECT Id, Title, Mx_Document_Type__c, Mx_Document_Verification_Status__c,
                                                        File_Link__c, FileType, VersionNumber, FileExtension, CreatedDate,
                                                        ContentDocumentId, Mx_Document_Verification_Notes__c
                                                        FROM ContentVersion WHERE Mx_Store_Id__c =:strStoreId
                                                        Order by CreatedDate DESC, VersionNumber DESC]){

                if(docTypesDups.contains(cv.Mx_Document_Type__c)){
                    continue ;
                }
                docTypesDups.add(cv.Mx_Document_Type__c);
                returnFiles.add(cv);
            }

            objDataWrapper.StoreId = strStoreId;
            objDataWrapper.accountName = lstCase[0].account.name;
            objDataWrapper.lstContentVersion = returnFiles;

            return objDataWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String uploadCV(String base64, String filename, String storeId, String strDocumentType,
                                    String strNotes, String strVerificationStatus, String strTitle) {
        try{
            ContentVersion cv = new ContentVersion();
            if(base64 != null && base64 != ''){
                cv.VersionData = EncodingUtil.base64Decode(base64);
            }

            cv.Title = strTitle;
            cv.PathOnClient = filename;
            cv.Mx_Store_Id__c = storeId;
            cv.Mx_Document_Type__c = strDocumentType;
            cv.Mx_Document_Verification_Notes__c = strNotes;
            cv.Mx_Document_Verification_Status__c = strVerificationStatus;
            insert cv;
            return cv.Id;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

    }



    public Class DataWrapper{
        @AuraEnabled public String StoreId {set;get;}
        @AuraEnabled public String accountName {set;get;}
        @AuraEnabled public List<ContentVersion> lstContentVersion {set;get;}
        @AuraEnabled public String Status {set;get;}
        @AuraEnabled public String StatusReason {set;get;}
        @AuraEnabled public String StatusNotes {set;get;}
        @AuraEnabled public String businessVerificationId{set;get;}
    }

    public Class MasterDataWrapper{
        @AuraEnabled public List<String> lstDocTypeName {set;get;}
        @AuraEnabled public Map<String,List<String>> mapStatusToStatusReason {set;get;}
    }
}