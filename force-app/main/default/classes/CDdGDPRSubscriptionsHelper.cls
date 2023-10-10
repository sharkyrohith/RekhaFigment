/**
* CDdGDPRSubscriptionsHelper
*
* @author     Naga Dinesh Annapareddy
* @date  2021-10-14
* @decription : Class to Manage Subscriptions
*/
public class CDdGDPRSubscriptionsHelper {

    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    /**
    * @author     Naga Dinesh Annapareddy
    * @date  2021-10-28
    * @decription : Method to unsubscribe deserialized input is expected
    * Method to invoke once JSON is Translated
    */
    public static void manageSubscriptions(List<CDdGDPREmailObj.CDdGDPRSubscriptions> receivedPayload) {
        Boolean subEnabled = CDdGDPREmailHelper.ENABLE_DELIGHTED_TASK;
        if (subEnabled){
            subEnabled = CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Subscription__c != null
                            ? CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Subscription__c : false;
        }

        if(subEnabled){
            //Returns records with Respect to Object Records
            Map<String,List<sObject>> recordsToUpdateByObject = new Map<String,List<sObject>>();
            List<sObject> recordsToUpdate = new List<sObject>();
            CDdGDPREmailObj.CDdGDPRSubObject wrp = fillConsentObject(receivedPayload);
            for(String objectName:CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.keySet()){
                for(String persona:CDdGDPRConstants.PERSONA_OBJECTS.keySet()){
                    if(CDdGDPRConstants.PERSONA_OBJECTS.get(persona).contains(objectName)){
                        Map<String,sObject> recordsFromObject = getRecordsToUpdate(objectName, wrp);
                        if(recordsFromObject != null && recordsFromObject.size() > 0){
                            recordsToUpdateByObject.put(objectName,recordsFromObject.values());
                            recordsToUpdate.addAll(recordsFromObject.values());
                        }
                    }
                }
            }
            if(recordsToUpdate.size() > 0){
                createGDPRSubscriptionEvents(recordsToUpdate);
            }
        }
    }

    public static void processSubscriptionEvents(List<GDPR_Email_Action__e> subEventList){
        List<Sobject> recordsToUpdate = new List<SObject>();
        for(GDPR_Email_Action__e event: subEventList){
            sObject record = (sObject) JSON.deserialize(event.JSON_Body__c,sObject.class);
            recordsToUpdate.add(record);
        }
        CDdGDPREmailHelper.updateRecords(recordsToUpdate);
    }

    /**
    * @author     Naga Dinesh Annapareddy
    * @date  2021-10-28
    * @decription : Method to identify all emails that needs to be unsubscribed
    */
    private static CDdGDPREmailObj.CDdGDPRSubObject fillConsentObject(List<CDdGDPREmailObj.CDdGDPRSubscriptions> receivedPayload) {
        CDdGDPREmailObj.CDdGDPRSubObject wrp = new CDdGDPREmailObj.CDdGDPRSubObject();
        for(CDdGDPREmailObj.CDdGDPRSubscriptions payload:receivedPayload){
            wrp.emailList.add(payload.email);
            for(CDdGDPREmailObj.CDdGDPRSubscription subs : payload.subscriptions){
                String key = payload.email + CDdGDPRConstants.SEPARATOR + payload.persona;
                if (!wrp.emailSubMap.containsKey(key)){
                    wrp.emailSubMap.put(key, false);
                }
                if(subs.optOut){
                    wrp.emailSubMap.put(key, true);
                }
            }
        }
        return wrp;
    }

    /**
    * @author     Naga Dinesh Annapareddy
    * @date  2021-11-02
    * @decription : get queried Records in a Map
    */
    private static Map<String,sObject> getRecordsToUpdate(String objectName, CDdGDPREmailObj.CDdGDPRSubObject wrp){
        Map<String,sObject> recordsToUpdate = new Map<String,sObject>();
        Set<String> fieldSetValues = new Set<String>();
        Set<String> addQFields = new Set<String>();
        addQFields.add(CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName));
        addQFields.add(CDdGDPRConstants.OPT_OUT_FIELD.get(objectName));
        if(CDdGDPRConstants.ADDITIONAL_FIELDS.get(objectName) != null) {
            addQFields.addAll(CDdGDPRConstants.ADDITIONAL_FIELDS.get(objectName));
        }
        fieldSetValues.addAll(CDdGDPREmailHelper.getFieldsList(objectName,CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.get(objectName)));

        Map<String,sObject> objList = getMatchingsObjectRecords(objectName,fieldSetValues, wrp.emailList, addQFields);
        Map<String,List<sObject>> emailRecordMap = getEmailRecordMap(objList,fieldSetValues,wrp.emailList);
        Map<Id,String> personaMap = CDdGDPREmailHelper.getPersona(objList.values());

        for(string keyValue:emailRecordMap.keySet()){
            for (SObject recordVal : emailRecordMap.get(keyValue)){
                SObject record = recordVal;
                String persona = personaMap.get(record.Id);
                string key = keyValue + CDdGDPRConstants.SEPARATOR + persona;

                //Checks persona matches the received persona
                if(wrp.emailSubMap.containsKey(key)){
                    if(recordsToUpdate.containsKey(recordVal.Id)){
                        record = recordsToUpdate.get(recordVal.Id);
                    }

                    for(String field:fieldSetValues){
                        if(recordVal.get(field) != null
                            && (String)recordVal.get(field) != null
                            && (String)recordVal.get(field) == keyValue){
                            String emailLogs;
                            Set<String> emailIds = new Set<String>();
                            Boolean optOut = wrp.emailSubMap.get(key);
                            if(record.get(CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName)) != null){
                                emailLogs= (String)record.get(CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName));
                                emailIds.addAll(emailLogs.split(';'));
                                if (optOut && !emailIds.contains(keyValue)){
                                    emailIds.add(keyValue);
                                } else if(!optOut && emailIds.contains(keyValue)){
                                    emailIds.remove(keyValue);
                                }
                                emailLogs = String.join((Iterable<String>)emailIds, ';');
                            } else {
                                if (optOut){
                                    emailLogs= keyValue + ';';
                                }
                            }

                            if(!wrp.recordIdsAffected.contains(recordVal.id)){
                                Schema.SObjectType objectType = SOBJECT_TYPES.get(objectName);
                                SObject rec = objectType.newSObject();
                                rec.Id = recordVal.Id;
                                wrp.recordIdsAffected.add(recordVal.id);
                                rec.put(CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName),emailLogs);
                                rec.put(CDdGDPRConstants.OPT_OUT_FIELD.get(objectName),wrp.emailSubMap.get(key));
                                recordsToUpdate.put(recordVal.Id,rec);
                            }
                        }
                    }
                }
            }
        }
        return recordsToUpdate;
    }

    public static void createGDPRSubscriptionEvents(List<sObject> recordJson){
        List<GDPR_Email_Action__e> eventsToPublish = new List<GDPR_Email_Action__e>();
        for(sObject record:recordJson){
            string jsonValue = JSON.serialize(record);

            GDPR_Email_Action__e event = new GDPR_Email_Action__e();
            event.Service__c = CDdGDPRConstants.SUBSCRIPTION_EVENT_SERVICE;
            event.JSON_Body__c =jsonValue;
            eventsToPublish.add(event);
        }

        CDdGDPREmailHelper.publishGDPREmailEvent(eventsToPublish);
    }

    /**
    * @author     Naga Dinesh Annapareddy
    * @date  2021-11-02
    * @decription : get Records in Email record Map format
    */
    private static Map<String,List<sObject>> getEmailRecordMap(Map<String,sObject> matchingRecords,Set<String> fields, Set<String> matchedValues){
        Map<String,List<sObject>> returnMap = new Map<String,List<sObject>>();
        for(string recordId:matchingRecords.keySet()){
            sObject recordValue= matchingRecords.get(recordId);
            for(String field:fields){
                String fieldVal =  (String)recordValue.get(field);
                if (fieldVal != null){
                    fieldVal = fieldVal.toLowerCase();
                }
                if(fieldVal != null && matchedValues.contains(fieldVal)){
                    if (returnMap.containsKey(fieldVal)){
                        returnMap.get(fieldVal).add(recordValue);
                    } else {
                        returnMap.put(fieldVal,new List<SObject>{recordValue});
                    }
                }
            }
        }

        return returnMap;
    }

    //Generic Method which will return records based on matching Fields and seaching values
    public static Map<String,sObject> getMatchingsObjectRecords(String sObjectName, Set<String> matchingFields, Set<String> searchValues, Set<String> AdditionalQueryFields) {
        String queryFilters;
        String fieldsToQuery=' ';
        Map<String, Schema.SObjectField> fieldTypeMap=CDdGDPREmailHelper.getFieldTypes(sObjectName);
        for(String matchingField : matchingFields){
            if(fieldTypeMap.get(matchingField).getDescribe().getType() != Schema.DisplayType.TextArea ){
                if(queryFilters == NULL){
                    queryFilters=' ';
                } else {
                    queryFilters=queryFilters+' OR ';
                }

                queryFilters=queryFilters+matchingField +' =: searchValues';
            }
        }
        Set<String> queryFields= new Set<String>();
        queryFields.addAll(matchingFields);
        if(AdditionalQueryFields != NULL && AdditionalQueryFields.size()>0)
            queryFields.addAll(AdditionalQueryFields);
        for(String queryField:queryFields){
            fieldsToQuery += ','+queryField;
        }

        String query = 'Select id'+fieldsToQuery+' from '+sObjectName+' Where' +queryFilters;
        List<sObject> queryResults = Database.query(query);
        Map<String,sObject> queryResultsMap = new Map<String,sObject>();
        for(sObject qResult:queryResults) {
            queryResultsMap.put(qResult.Id,qResult);
        }
        return queryResultsMap;
    }
}