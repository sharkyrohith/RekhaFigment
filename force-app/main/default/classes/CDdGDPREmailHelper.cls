/**
    * @date 08/31/2021
    *
    * @description helper class for GDPR related triggers and classes.
    @author    | Raja  (Criticalriver)

    **/
    public class CDdGDPREmailHelper {

        /*** constants ***/
        public static final String CLASS_INFO = 'CDdGDPREmailHelper';
        public static final Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();
        public static final Id PERSON_ACCOUNT_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Consumer or Dasher').getRecordTypeId();
        public static final Id MARKETPLACE_ACCOUNT_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Marketplace').getRecordTypeId();
        public static final Id MERCHANT_LEAD_RECORDTYPEID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Master Lead').getRecordTypeId();
        public static final Id DDFW_ACCOUNT_RECORDTYPEID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('DoorDash for Business').getRecordTypeId();
        public static final Id DDFW_LEAD_RECORDTYPEID = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('DoorDash for Business').getRecordTypeId();

        public static final GDPR_Setting__c SETTING = GDPR_Setting__c.getInstance();
        public static final String CASE_QUERY = 'select Id, {0} from Case where Id =: caseIdList';
        public static final String QUERY_FIELD_SEPARATOR = ',';
        public static final String ENC_VAL_TEMPLATE = 'Email={0}&Persona={1}';
        public static final String ENC_METHOD = 'AES256';
        public static final INTEGER RETRY_DEFAULT = 2;
        public static Boolean ENABLE_CREATE_CONTACT = true;
        public static Boolean ENABLE_SUBSCRIPTION = true;
        public static Boolean ENABLE_DELIGHTED_TASK = true;


        public static String getObjectName(Id recordId){
            if(recordId == null){
                return null;
            } else {
                return (String) recordId.getSObjectType().getDescribe().getName();
            }
        }

        public static Map<String, Schema.SObjectField> getFieldTypes(String objectName) {
            Schema.SObjectType objectSchema = SOBJECT_TYPES.get(objectName);
            Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
            return fieldMap;
        }

        public static List<String> getFieldsList(String objectName,String fieldSetName){
            List<String> fields = new List<String>();
            SObjectType objectType = SOBJECT_TYPES.get(objectName);
            Schema.FieldSet fieldSetObj = objectType.getDescribe().FieldSets.getMap().get(fieldSetName);
            if( fieldSetObj != null && !fieldSetObj.getFields().isEmpty()){
                for(Schema.FieldSetMember objField : fieldSetObj.getFields()){
                    fields.add(objField.getFieldPath());
                }
            }
            return fields;
        }

        public static void updateRecords(List<sObject> recordsToUpdate){

            //Updated the retry logic for failed records using CDdRetryQueueable framework.
            List<sObject> errRecordsToReprocess=new List<sObject>();
            if (recordsToUpdate != null && !recordsToUpdate.isEmpty()) {
                List<Database.SaveResult> sResults = Database.update(recordsToUpdate,false);
                for (Integer i = 0; i < sResults.size(); i++) {
                    Database.SaveResult sr = sResults[i];
                    if (!sr.success) {
                        for (Database.Error err : sr.getErrors()) {
                            // add the sObject records which failed.
                            if(err.getStatusCode() == StatusCode.UNABLE_TO_LOCK_ROW){
                                errRecordsToReprocess.add(recordsToUpdate[i]);
                            }
                        }
                    }
                }
                CDdErrorUtilities.publishException('SObject ',CLASS_INFO +'.updateRecords', sResults);
            }
            if (!errRecordsToReprocess.isEmpty()) {
                System.enqueueJob(new CDdRetryQueueable(errRecordsToReprocess, 'UPDATE', 'CDdGDPREmailHelper.updateRecords'));
            }
        }

        public static void publishGDPREmailEvent(List<GDPR_Email_Action__e> listofEvents){
            if (!listofEvents.isEmpty()){
                List<Database.SaveResult> sResults = EventBus.publish(listofEvents);
                CDdErrorUtilities.publishException('GDPR_Email_Action__e ',CLASS_INFO +'.PublishGDPREmailEvent', sResults);

            }
        }

        public static Map<Id,String> getPersonaLanguageFromCase(List<Id> recordIds){
            List<SObject> records = getCaseObjects(recordIds);
            Map<Id,String> langMap = getCassieLanguage(records);

            Map<Id, SObject> caseToObj = new Map<Id, SObject>();
            Map<Id, SObject> caseMap = new Map<Id, SObject>();
            for(sObject sObj:records){
                if(sObj.Id.getsobjecttype() ==  Case.sObjectType){
                    caseMap.put(sObj.Id, sObj);
                    if (sObj.get('AccountId') != null){
                        SObject acc = sObj.getSObject('Account');
                        caseToObj.put(sObj.Id, acc);
                    } else if ( sObj.get('contactId') != null){
                        SObject ctc = sObj.getSObject('Contact');
                        caseToObj.put(sObj.Id, ctc);
                    }
                }
            }

            Map<Id, String> objToPersona = getPersona(caseToObj.values());
            Map<Id, String> retVal = new Map<Id, String>();
            for (Id caseId : caseToObj.keySet()){
                SObject obj = caseToObj.get(caseId);
                string persona = objToPersona.containsKey(obj.Id) ? objToPersona.get(obj.Id) : '';
                String lang = langMap.containsKey(caseId) ? langMap.get(caseId) : '';
                retVal.put(caseId, persona + CDdGDPRConstants.SEPARATOR + lang);
            }
            return retVal;
        }

        public static Map<Id,String> getCassieLanguage(List<SObject> records){
            List<GDPR_Language_Mapping__c> langMaps =  GDPR_Language_Mapping__c.getAll().values();
            Map<String,String> cseLangToCassieLang = new Map<String,String>();
            for (GDPR_Language_Mapping__c lang : langMaps){
                cseLangToCassieLang.put(lang.Case_Language__c, lang.Cassie_Language__c);
            }

            Map<Id,String> retVal = new Map<Id,String>();
            for (SObject obj : records){
                String lg = (String) obj.get(CDdGDPRConstants.CASE_LANGUAGE_FIELD);
                if (String.isNotBlank(lg)
                        && cseLangToCassieLang.containsKey(lg)){
                    retVal.put(obj.Id, cseLangToCassieLang.get(lg));
                }
            }
            return retVal;
        }

        public static List<SObject> getCaseObjects(List<String> caseIdList) {
            String fieldsToQuery = String.join(CDdGDPRConstants.CASE_QUERY_FIELDS, QUERY_FIELD_SEPARATOR);
            String query = String.format(CASE_QUERY, new List<String>{fieldsToQuery});

            return Database.query(query);
        }

        public static Map<Id,String> getPersona(List<Sobject> records){
            Map<Id,String> personaMap=new Map<Id,String>();

            if(!records.isEmpty()){
                for(sObject sObj:records){
                        // prepare persona for account
                    if(sObj.Id.getsobjecttype() ==  Account.sObjectType){
                        if(sObj.get('RecordTypeId') != NULL){
                            if(sObj.get('RecordTypeId') == PERSON_ACCOUNT_RECORDTYPEID){
                                if(sObj.get('CustomerNo__pc') == NULL && sObj.get('DasherNo__pc') != NULL){
                                    personaMap.put(sObj.Id,CDdGDPRConstants.DX_PERSONA_VALUE);
                                } else if (sObj.get('CustomerNo__pc') == NULL && sObj.get('MerchantNo__c') != NULL){
                                    personaMap.put(sObj.Id,CDdGDPRConstants.MX_PERSONA_VALUE);
                                } else if (sObj.get('CustomerNo__pc') != NULL){
                                    personaMap.put(sObj.Id,CDdGDPRConstants.CX_PERSONA_VALUE);
                                }
                            } else if(sObj.get('recordtypeid') == MARKETPLACE_ACCOUNT_RECORDTYPEID){
                                personaMap.put(sObj.Id,CDdGDPRConstants.MX_PERSONA_VALUE);
                            } else if(sObj.get('recordtypeid') == DDFW_ACCOUNT_RECORDTYPEID){
                                personaMap.put(sObj.Id,CDdGDPRConstants.DDFW_PERSONA_VALUE);
                            }
                        }
                    }

                    // prepare persona for Contact
                    if(sObj.Id.getsobjecttype() ==  Contact.sObjectType){
                        if(sObj.get('IsPersonAccount') == TRUE ){
                            if( sObj.get('CustomerNo__c') == NULL
                                && sObj.get('DasherNo__c') != NULL){
                                personaMap.put(sObj.Id,CDdGDPRConstants.DX_PERSONA_VALUE);
                            } else if( sObj.get('CustomerNo__c') != NULL){
                                personaMap.put(sObj.Id,CDdGDPRConstants.CX_PERSONA_VALUE);
                            }
                        } else {
                            if (sObj.get('Account_Record_Type_Name__c') == CDDGDPRConstants.ACCOUNT_DDFW_RECORD_TYPE){
                                personaMap.put(sObj.Id,CDdGDPRConstants.DDFW_PERSONA_VALUE);
                            } else {
                                personaMap.put(sObj.Id,CDdGDPRConstants.MX_PERSONA_VALUE);
                            }
                        }
                    }

                    // prepare persona for Lead
                    if(sObj.Id.getsobjecttype() ==  Lead.sObjectType){
                        if (sObj.get('RecordTypeId') == DDFW_LEAD_RECORDTYPEID){
                            personaMap.put(sObj.Id,CDdGDPRConstants.DDFW_PERSONA_VALUE);
                        } else if (sObj.get('RecordTypeId') == MERCHANT_LEAD_RECORDTYPEID){
                            personaMap.put(sObj.Id,CDdGDPRConstants.MX_PERSONA_VALUE);
                        }
                    }
                }
            }

            return personaMap;
        }

        public static CDdGDPREmailObj.CDdGDPREmailFields getEmailFields(SObject record, String objectName){
            CDdGDPREmailObj.CDdGDPREmailFields retVal = new CDdGDPREmailObj.CDdGDPREmailFields();
            retVal.emailOptOutField = CDdGDPRConstants.OPT_OUT_FIELD.get(objectName);
            retVal.emailOptOutLogField = CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName);
            retVal.isPersonAccount = false;
            if (objectName == CDdGDPRConstants.ACCOUNT_OBJECT){
                if (record.get(CDdGDPRConstants.PERSON_FIELD) != null){
                    retVal.isPersonAccount = (Boolean) record.get(CDdGDPRConstants.PERSON_FIELD);
                }

                if (retVal.isPersonAccount){
                    retVal.personEmailOptOutField = CDdGDPRConstants.PERSON_OPT_OUT_FIELD;
                    retVal.personEmailOptOutLogField = CDdGDPRConstants.PERSON_OPT_EMAIL_LOG_FIELD;
                }
            }
            return retVal;
        }

        public static String getEncryptedSubscriptionLink(String email, String persona, String lang){
            String retVal = '';
            if (SETTING.Name != null){
                if (persona == CDdGDPRConstants.CX_PERSONA_VALUE){
                    retVal = SETTING.CX_Unsubscribe_Link__c;
                } else if (persona == CDdGDPRConstants.DX_PERSONA_VALUE){
                    retVal = SETTING.DX_Unsubscribe_Link__c;
                } else if (persona == CDdGDPRConstants.MX_PERSONA_VALUE){
                    retVal = SETTING.MX_Unsubscribe_Link__c;
                }  else if (persona == CDdGDPRConstants.DDFW_PERSONA_VALUE){
                    retVal = SETTING.DDFW_Unsubscribe_Link__c;
                }

                String encVal = String.format(ENC_VAL_TEMPLATE, new List<String>{email, persona});
                Blob keyBlob = EncodingUtil.base64Decode(SETTING.Encryption_Key__c);
                Blob encBlob = Blob.valueOf(encVal);
                Blob encrypted = Crypto.encryptWithManagedIV(ENC_METHOD, keyBlob, encBlob);

                String strEnc = EncodingUtil.base64Encode(encrypted);
                return String.format(retVal, new List<String>{strEnc, lang});
            } else {
                return retVal;
            }
        }
        public static string getFieldsToQuery(String objectName){
            List<String> fieldsList = new List<String>();
            String fieldstoQuery;
            if(String.isNotBlank(objectName)){
                // email fields inn Meta Data
                if(CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.containskey(objectName)){
                    fieldsList.addAll(CDdGDPREmailHelper.getFieldsList(objectName,
                    CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.get(objectName)));
                }
                //Opn In/opt out /log fields
                if(CDdGDPRConstants.OPT_OUT_FIELD.containskey(objectName))
                    fieldsList.add(CDdGDPRConstants.OPT_OUT_FIELD.get(objectName));
                if(CDdGDPRConstants.OPT_EMAIL_LOG.containskey(objectName))
                    fieldsList.add(CDdGDPRConstants.OPT_EMAIL_LOG.get(objectName));
                //get person opt in/out and logs if account
                if(objectName == CDdGDPRConstants.ACCOUNT_OBJECT){

                    fieldsList.add(CDdGDPRConstants.PERSON_FIELD);
                    fieldsList.add(CDdGDPRConstants.PERSON_OPT_OUT_FIELD);
                    fieldsList.add(CDdGDPRConstants.PERSON_OPT_EMAIL_LOG_FIELD);
                }
                // get the additional fields
                if(CDdGDPRConstants.ADDITIONAL_FIELDS.containskey(objectName))
                fieldsList.addAll(CDdGDPRConstants.ADDITIONAL_FIELDS.get(objectName));
            }
            //remove null values
            Set<String> tempfieldsSet = new Set<String>(fieldsList);
            tempfieldsSet.remove(null);

            if(!tempfieldsSet.isEmpty() && tempfieldsSet != null)
            fieldstoQuery= String.join(new list<string>(tempfieldsSet),cddcoreconstants.DELIMITER_COMMA);

            return fieldstoQuery;
        }
    }