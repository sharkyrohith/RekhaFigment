public with sharing class CDdCaseRedirectToDispatchController {
    
    public String defaultURL {get;set;}
    String caseId {get; set;}
    Case thisCase {get;set;}
    ApexPages.StandardController controller{get;set;}
    List<String> caseFields = new List<String>(); 
    String preChatCategory {get;set;}
    String preChatSubCategory {get;set;}
    String customerNo {get;set;}
    String deliveryNumber {get;set;}
    Id recordTypeId {get;set;}
    String issueCategory{get;set;}
    String issueSubCategory{get;set;}
    String customerType{get;set;}
    String deliveryUUID {get;set;}

    Map<String, Dispatch_Mapping__mdt> categoryURLMapping = new Map<String, Dispatch_Mapping__mdt>(); 
    
    public CDdCaseRedirectToDispatchController(ApexPages.StandardController standardController){
        caseFields.add('Pre_Chat_Category__c');
        caseFields.add('Pre_Chat_Sub_Category__c');
        // change this to Delivery_UUID__c when UUID is available. 
        caseFields.add('DeliveryNo__c');
        caseFields.add('DeliveryUUID__c');
        caseFields.add('RecordTypeId');
        caseFields.add('Account.CustomerNo__pc');
        caseFields.add('Issue__c');         //  Sub category
        caseFields.add('Issue_Type__c');    //  Category
        caseFields.add('Customer_Type__c'); 


        caseId = standardController.getId();

        if (!Test.isRunningTest()) standardController.addFields(caseFields);
        controller = standardController; 
        thisCase = (Case) standardController.getRecord(); 
        preChatCategory = thisCase.Pre_Chat_Category__c;
        preChatSubCategory = thisCase.Pre_Chat_Sub_Category__c; 
        recordTypeId = thisCase.recordTypeId; 
        deliveryNumber = String.valueOf(thisCase.DeliveryNo__c); 
        customerNo = String.valueOf(thisCase.Account.CustomerNo__pc); 
        populateCategoryURLMapping(); 
        defaultURL = getRedirectPageRef('Default',customerNo).getURL();
        issueCategory = thisCase.Issue_Type__c; 
        issueSubCategory = thisCase.Issue__c;
        customerType = thisCase.Customer_Type__c; 
        deliveryUUID = thisCase.DeliveryUUID__c;
    }
    

    public PageReference redirectPage() {
        // Supprot RecordType's Developer Name is 'Customer';
        PageReference pgReference;
        Id supportRecordTypeId = CDdSchemaUtils.getRecordTypeIdByDeveloperName('Case', 'Customer');
        String urlToRedirectTo; 
        String categoryMapKey; 
        String key; 
        thisCase = (Case) controller.getRecord(); 
        preChatCategory = thisCase.Pre_Chat_Category__c;
        RecordTypeId = thisCase.recordTypeId; 
        key = null;
        // If Issue Type and Issue are populated, use these values first since they are manually populated by Agents
        if(!String.isBlank(issueCategory) && (deliveryNumber != null || deliveryUUID != null)) {
            key = String.isBlank(issueSubCategory) ? issueCategory : issueCategory + issueSubCategory; 
            key = key + customerType; 
            key = key.toLowerCase(); 
            if(deliveryUUID != null ){
                pgReference = getRedirectPageRef(key, deliveryUUID);
            } else {
                pgReference = getRedirectPageRef(key, deliveryNumber);
            }
        }
        // If Delivery Number is not populated, use Customer Number
        else if(!String.isBlank(issueCategory) && deliveryNumber == null) {
            pgReference = getRedirectPageRef('default',customerNo);
        }
        else if(String.isBlank(preChatCategory) || deliveryNumber == null) {
            pgReference = getRedirectPageRef('default',customerNo);
        } else {
            key = String.isBlank(preChatSubCategory) ? preChatCategory : preChatCategory + preChatSubCategory; 
            key = key + customerType; 
            key = key.toLowerCase(); 
            if(deliveryUUID != null ){
                pgReference = getRedirectPageRef(key, deliveryUUID);
            } else {
                pgReference = getRedirectPageRef(key, deliveryNumber);
            }
        }
         
        return pgReference; 
    }

    /**
     * Create Map for Dispatch Mapping Custom Metadat
     *          Key = Category + SubCategory
     *          Value = Mapping record
     */
    private void populateCategoryURLMapping() {
        List<Dispatch_Mapping__mdt> dispatchMappingList = [SELECT Case_Sub_Category__c, Category__c, Is_Active__c, URL__c, Customer_Type__c 
                                                            FROM Dispatch_Mapping__mdt
                                                            WHERE Is_Active__c = true];
        
        String tempKey;
        for(Dispatch_Mapping__mdt mapping : dispatchMappingList) {
            tempKey = mapping.Category__c; 
            if(!String.isBlank(mapping.Case_Sub_Category__c)) {
                //if the Sub Category is not blank, concatinate Category and Sub Category to use as a Key.
                tempKey = tempKey + mapping.Case_Sub_Category__c;
            } 
            if(!String.isBlank(mapping.Customer_Type__c)) {
                tempKey = tempKey + mapping.Customer_Type__c;
            }
            tempKey = tempKey.toLowerCase();

            categoryURLMapping.put(tempKey, mapping);
            System.debug('><> ' + tempKey); 
        }
    }

    /**
     * replaces the ID holder from the Custom metadata with the ID provided
     */
    private PageReference getRedirectPageRef(String key, String replacementId) {
        String url;
        System.debug('><> Key = ' + key);
        if(categoryURLMapping.containsKey(key)) {
            url = categoryURLMapping.get(key).URL__c; 
        } else {
            System.debug(categoryURLMapping.get('default')); 
            url = categoryURLMapping.get('default').URL__c; 
            // for default always use CustomerNo
            url = url.replace('{!IDGoesHere}', customerNo == null ? '' : customerNo ); 
        }
        System.debug('><> ' + url);
        url = url.replace('{!IDGoesHere}', replacementId == null ? '' : replacementId ); 
        return(new PageReference(url)); 
    }
}