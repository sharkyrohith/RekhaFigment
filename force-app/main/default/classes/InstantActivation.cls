@RestResource(urlMapping='/InstantActivation/*')
global with sharing class InstantActivation {
    static final Map<String, Map<String, String>> dataMapping = new Map<String, Map<String, String>>{
        'ssme_escalation_date_time__c' => new Map<String, String>{'fieldName' => 'SSME_Escalation_Date_Time__c', 'dataType' => 'datetime'},
        'ssme_expiration_date_time__c' => new Map<String, String>{'fieldName' => 'SSME_Expiration_Date_Time__c', 'dataType' => 'datetime'},
        'ssme_menu_completion_date_time__c' => new Map<String, String>{'fieldName' => 'SSME_Menu_Completion_Date_Time__c', 'dataType' => 'datetime'},
        'menu_to_be_completed_by__c' => new Map<String, String>{'fieldName' => 'Menu_to_be_completed_by__c', 'dataType' => 'string'}
    };

    @testVisible static final Map<String, RecordTypeInfo> OPP_RT_INFO = 
        Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

    @HttpPatch
    global static void patchOpportunity() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Id oppId; 
        try{
            oppId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1); 
            if(oppId.getSobjectType() != Schema.Opportunity.getSObjectType()){
                res.statusCode = 404;
                res.responseBody = Blob.valueOf('Resource Id is not a valid Opportunity record Id.');
                return ;
            }
            Opportunity opp = [SELECT Id, SSME_Escalation_Date_Time__c, SSME_Expiration_Date_Time__c, SSME_Menu_Completion_Date_Time__c, 
                                    Menu_to_be_completed_by__c FROM Opportunity WHERE Id = :oppId FOR UPDATE]; // WITH SECURITY_ENFORCED];
            Map<String, Object> dataForUpdate = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            Map<String, String> field;
            for(String key: dataForUpdate.keySet()){
                field = dataMapping.get(key.toLowerCase());
                if(field == null){
                    continue;
                }
                if(field.get('dataType') == 'datetime'){
                    opp.put(field.get('fieldName'), DateTime.parse(String.valueOf(dataForUpdate.get(key))));
                    continue;
                }
                opp.put(field.get('fieldName'), dataForUpdate.get(key));
            }
            update opp;
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Record updated successfully.');
        }catch(Exception e){
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Payload received and may need a human to process. '+e.getMessage());
        }finally{
            Apex_Log__c log = new Apex_Log__c(Class_Name__c = 'InstantActivation: '+system.now().format(), 
                    Method_Name__c = 'getStoreWithMarketplaceOpportunities', Log_Level__c = 'Info', 
                    Log__c = '{"requestURI":'+req.requestURI+', "req_resourcePath":'+req.resourcePath+', "requestBody":'+req.requestBody.toString()
                            +', "req_remoteAddress":'+req.remoteAddress+', "responseBody":'+res.responseBody.toString()+', "responseStatusCode":'+res.statusCode+'} ');
            insert log;
            if(res.statusCode != 200){
                insert new Opportunity_Error_Log__c(Apex_Log__c = log.Id, Code_Type__c = 'Http', Status__c = 'Pending', 
                    Status_Code__c = String.valueOf(res.statusCode), Parent_Id__c = oppId,
                    OwnerId = [SELECT Id From Group WHERE Type='Queue' AND Name = 'Opportunity Error Log'].Id);
            }
        }
    }
}