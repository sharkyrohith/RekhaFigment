/*
*@Description: Class to get the APICredential__mdt metadata records filtered by Category field
@Author : Veera Maddukuri
@Date : 2021-11
*/
public with sharing class CDdAPICredentialData {
   
    //Categories for API credentials
    public static final String OCUS_CATEGORY = 'OCUSCredentials';
    public static final String OCUS_CATEGORY_WEBHOOK = 'OCUSWebhookSecretKey';

    public static Map<String,CredentialWrapper> getCredentialWrapper(String category){
        return initializeCredentials(new List<String>{category});
    }

    //Method to create CredentialWrapper class from Custom metadata with Authorization details(Endpoint, Accesstoken ...) based on the Country
    private static Map<String,CredentialWrapper> initializeCredentials(List<String> categoryList){
        Map<String,CredentialWrapper> CredentialData = new Map<String,CredentialWrapper>();

        List<APICredential__mdt> apiCredentialMetadata = getApiCredentialMetadataByCategory(categoryList);

        for(APICredential__mdt cred : apiCredentialMetadata){
            CredentialWrapper cw = new CredentialWrapper();
            cw.isSandbox = CDdUtilities.getIsSandbox();
            if(cw.isSandbox){
                cw.accessToken = cred.SandboxAccessToken__c;
                cw.namedCredential =  cred.SandboxNamedCredential__c;
            }else{
                cw.accessToken = cred.AccessToken__c;
                cw.namedCredential =  cred.NamedCredential__c;
            }
            
            cw.developerName = cred.DeveloperName;
            cw.getSuffix = cred.GETMethodSuffix__c;
            cw.offerId = getOfferId(cred.OfferList__c);
            cw.postSuffix = cred.POSTMethodSuffix__c;
            cw.masterLabel = cred.MasterLabel;
            cw.organization_id = cred.Organization_Id__c;
            CredentialData.put(cred.DeveloperName, cw);
        }
        return CredentialData;
        
    }

    //OCUS Specific method to parse OfferList
    private static String getOfferId(String offerPicklist){
        if(String.isNotBlank(offerPicklist)){
            List<String> offerSplit = offerPicklist.split(':');
            if(offerSplit.size() > 1){
                return offerSplit[1].trim();
            }
        }
        return null;
    }

    private static List<APICredential__mdt> getApiCredentialMetadataByCategory(List<String> categoryName){
        return  [
            SELECT Id, MasterLabel, DeveloperName, AccessToken__c, Category__c, NamedCredential__c, GETMethodSuffix__c, 
            OfferList__c, POSTMethodSuffix__c, SandboxAccessToken__c, SandboxNamedCredential__c, Organization_Id__c  
            FROM APICredential__mdt 
            WHERE Category__c IN :categoryName
        ];
    }

    public class CredentialWrapper{
        public String accessToken;
        public Boolean isSandbox;
        public String namedCredential;
        public String offerId;
        public String postSuffix;
        public String getSuffix;
        public String developerName;
        public String masterLabel;
        public String organization_id;
    }
}