/**
 * @author			Jose Vega <jose.vega@doordash.com>
 * @created			06 / 01 / 2021
 * @description		BZAP-8953 Handles all Denali Cherwell interactions associated
 * with consolidated API.
 *
*/
public with sharing class CDdDenaliV2Handler {

    public class DenaliV2Exception extends Exception {}

    /*
    * @description Acquire setting label based on environment
    */
    public static Organization org = [
        SELECT IsSandbox
        FROM Organization
        WHERE  Id =:UserInfo.getOrganizationId()
    ];
    public static String settingLabel = org.IsSandbox ? 'UAT' : 'Prod';

     /**
    * @description Setting for Denali
    */
    public static Denali_Setting__mdt setting = [
        SELECT
            URL_V2__c,
            Username_V2__c,
            Password_V2__c
        FROM Denali_Setting__mdt
        WHERE MasterLabel =: settingLabel];

    /**
    * @description Save Case to Cherwell, used in batch
    */
    public static void saveCasesToDenali(List<Id> casesId) {
        if (shouldSkipSendToDenali()) return;

        List<SObject> results = new List<SObject>();
        for (Id caseId : casesId){
            List<SObject> res = saveCaseToDenali(caseId, false);
            if (res.size() > 0){
                results.addAll(res);
            }
        }

        if (results.size() > 0){
            CDdCaseTriggerHelperV2.SEND_TO_DENALI = false;
            update results;
            CDdCaseTriggerHelperV2.SEND_TO_DENALI = true;
        }
    }

    /**
    * @description save Case to Cherwell individual case, in VF and called by trigger
    */
    public static List<SObject> saveCaseToDenali(Id currentCaseId, Boolean saveObjects) {
        if (shouldSkipSendToDenali()) return null;

        List<SObject> objToUpdate = new List<SObject>();

        Case currentCase = queryDenaliCase(currentCaseId);

        try {
            CDdDenaliV2RequestObject.CherwellBody body = new CDdDenaliV2RequestObject.CherwellBody();
            body.operation = CDdDenaliV2RequestObject.getOperation(currentCase);
            String jsonBody = CDdDenaliV2RequestObject.generateJSON(body, currentCase);

            if (body.isValid()) {
                performHttpRequest(jsonBody, currentCaseId);
            }

            // clear the denali apex logs
            currentCase.Denali_Apex_Log__c = null;
            currentCase.Send_To_Denali__c = false;
            objToUpdate.add(currentCase);
        } catch(Exception e) {
            List<Apex_Log__c> logs = CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdDenaliV2Handler');
            System.debug(logs);
            currentCase.Denali_Apex_Log__c = logs[0].Id;
            objToUpdate.add(currentCase);

            if (System.isBatch()){
                return objToUpdate;
            } else {
            	throw e;
            }
        } finally {
            if (objToUpdate.size() > 0 && saveObjects) {
                update objToUpdate;
            }
        }

        return objToUpdate;
    }

    private static Boolean shouldSkipSendToDenali() {
        return !CDdExperimentSvc.getFeatureFlag('Send_To_Denali_V2__c');
    }

    /**
    * @description Get access token from Cherwell
    */
    public static String generateAccessToken(String username, String password){
        Blob headerValue = Blob.valueOf(username + ':' + password);
        return EncodingUtil.base64Encode(headerValue);
    }

    /**
     * @description POST to API
     * @TODO : leverage the CDdRestConnectorSvc
     */
    public static void performHttpRequest(String body, String recordId) {
        //recordId is only passed in for logging purposes
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String url =  setting.URL_V2__c;
        String token = generateAccessToken(setting.Username_V2__c, setting.Password_V2__c);

        request.setEndpoint(url);
        request.setHeader('content-type', 'application/json');
        request.setHeader('Authorization','Basic ' + token);
        request.setMethod('POST');

        System.debug('json body:' + body);

        request.setBody(body);

        HttpResponse response = http.send(request);

        insert new Apex_Log__c(
            Class_Name__c = 'CDdDenaliV2Handler',
            Record_ID__c = recordId,
            Callout_Request__c = 'request-to-string --> ' + request.toString() + '|| request-body --> ' + request.getBody(),
            Callout_Response__c = 'response-to-string --> ' + response.toString() + '|| response-body --> ' + response.getBody(),
            Log__c =  'request.getBody: '+ request.getBody() +' ||response.getStatusCode: '+ response.getStatusCode() + ' ||response.getStatus: '+response.getStatus() + ' ||response.getBody: '+response.getBody(),
            Method_Name__c = 'performHttpRequest',
            Log_Level__c = 'Info');

        if (response.getStatusCode() != 200) {
            throw new DenaliV2Exception('Denali API request failed to receive status code 200.');
        }

    }

    /**
    * @description Query the case object with object mappings
    */
    @TestVisible
    private static Case queryDenaliCase(String caseId){

        Set<String> flds = null;
        flds = getFieldsFromMap(CDdDenaliV2RequestObject.accountFieldMapping, flds);
        flds = getFieldsFromMap(CDdDenaliV2RequestObject.contactFieldMapping, flds);
        flds = getFieldsFromMap(CDdDenaliV2RequestObject.caseFieldMapping, flds);

        String qry = 'SELECT ';
        qry += String.join(new List<String>(flds), ',');
        qry += ' FROM Case WHERE Id =: caseId';

        System.debug ('qry:' + qry);

        return Database.query(qry);
    }

    private static Set<String> getFieldsFromMap(Map<String, String> fieldMap, Set<String> flds){
        if (flds == null){
            flds = new Set<String>();
        }

        for (String fld : fieldMap.values()){
            if (!flds.contains(fld) && !fld.contains('String.') && !String.isBlank(fld)){
                    flds.add(fld);
            }
        }
        return flds;
    }
}