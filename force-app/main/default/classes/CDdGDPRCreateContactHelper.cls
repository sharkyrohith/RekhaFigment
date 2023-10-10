public class CDdGDPRCreateContactHelper {

    /*** constants ***/
    public static final String CLASS_INFO = 'CDdGDPRCreateContactHelper';
    public static final String CREATE_GDPR_EMAIL_CREATE_CONTACT_EVENT  = 'createGDPREmailCreateContactEvent';
    public static final String CREATE_CONTACT_SERVICE = 'CreateContact';
    public static final Integer OPT_IN = 1;

    /**@author    | Raja  (Criticalriver)
    * @date       | 2021-10-30
    * @ticket     |
    * @param      | List<sObject> newList, Map<Id, sObject> oldMap,String objectName,String fieldSetName
    * @return void
    **/
    public static void createGDPREmailCreateContactEvent(List<sObject> newList, Map<Id, sObject> oldMap){

        List<GDPR_Email_Action__e> gdprEmailActionList=new List<GDPR_Email_Action__e>();
        list<string> fieldsToCheck=new list<string>();
        map<Id,String> personaMap=new map<Id,String>();
        String objectName = CDdGDPREmailHelper.getObjectName(newList[0].Id);
        String fieldSetName = CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.get(objectName);
        String fieldsToQuery;
        set<Id> recorIds=new set<Id>();
        List<sObject> lstSObject= new  List<sObject>();

        Boolean creationEnabled = CDdGDPREmailHelper.ENABLE_CREATE_CONTACT;
        if (creationEnabled){
            creationEnabled = CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Creation__c != null
                                    ? CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Creation__c : false;
        }

        if(creationEnabled){
            try {
                if(objectName != null && fieldSetName != null){
                    if(CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.containskey(objectName)){
                        fieldsToCheck = CDdGDPREmailHelper.getFieldsList(objectName,
                                CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.get(objectName));
                    }
                    //get the list of the fields to query
                    if(!newList.isEmpty() && newList != null){
                        for(sObject record:newList){
                            recorIds.add(record.id);
                        }
                        if(!recorIds.isEmpty() && recorIds != null){
                            fieldsToQuery=CDdGDPREmailHelper.getFieldsToQuery(objectName);
                            if(!String.isBlank(fieldsToQuery))
                            lstSObject = Database.query('select id,'+ fieldsToQuery + ' from '+objectName+' where Id IN: recorIds');
                        }
                    }
                    //get personaMap
                    if(!lstSObject.isEmpty())
                    personaMap=CDdGDPREmailHelper.getPersona(lstSObject);
                    if(!fieldsToCheck.isEmpty() && !lstSObject.isEmpty() && !personaMap.isEmpty()){
                        for(sObject record:lstSObject){
                            if(personaMap.containskey(record.id)){
                                for (string field : fieldsToCheck){
                                    String emailAddress=(string)record.get(field);
                                    if(String.isNotBlank(emailAddress)
                                        && !CDdGDPRConstants.EXCLUDED_DOMAINS.contains(emailAddress.substringAfter(CDdCoreConstants.DELIMITER_AT))){
                                        GDPR_Email_Action__e ge=new GDPR_Email_Action__e();
                                        ge.Field_Name__c=field;
                                        ge.Record_ID__c=record.id;
                                        ge.Persona__c=personaMap.get(record.id);
                                        ge.Old_Value__c='';
                                        ge.Service__c=CREATE_CONTACT_SERVICE;
                                        ge.JSON_Body__c= JSON.serialize(record);
                                        if ((oldMap == null && record.get(field) != null)
                                            || (record.get(field) != null
                                                && (record.get(field) != oldMap.get(record.Id).get(field)))){
                                            gdprEmailActionList.add(ge);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if(!gdprEmailActionList.isEmpty()){
                    CDdGDPREmailHelper.PublishGDPREmailEvent(gdprEmailActionList);
                }
            }
            catch(Exception ex){
                CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()},
                    CLASS_INFO, CREATE_GDPR_EMAIL_CREATE_CONTACT_EVENT, LoggingLevel.ERROR);
            }
        }
    }

    /**@author    | Tia Xuan
    * @date       | 2022-02
    * @ticket     |
    * @param      | List<sObject> newList, Map<Id, sObject> oldMap
    * @return void
    **/
    public static void treatChangedEmailAudit(List<sObject> newList, Map<Id, sObject> oldMap){
        Boolean creationEnabled = CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Creation__c != null
                                    ? CDdGDPREmailHelper.SETTING.Enable_GDPR_Contact_Creation__c : false;

        if(creationEnabled){
            if(newList.size() > 0){
                List<String> fieldsToCheck=new List<String>();
                String objectName = CDdGDPREmailHelper.getObjectName(newList[0].Id);

                if(objectName != null){
                    if(CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.containskey(objectName)){
                        fieldsToCheck = CDdGDPREmailHelper.getFieldsList(objectName,
                                CDdGDPRConstants.SUBSCRIPTION_FIELDSETS.get(objectName));
                    }
                    if(!fieldsToCheck.isEmpty()){
                        for(sObject record:newList){
                            CDdGDPREmailObj.CDdGDPREmailFields emailFlds = CDdGDPREmailHelper.getEmailFields(record,objectName);
                            String emailLogVal = (String) record.get(emailFlds.emailOptOutLogField);
                            Boolean emailOptOut = (Boolean) record.get(emailFlds.emailOptOutField);
                            Set<String> emailLogList = new Set<String>();
                            if (!String.isBlank(emailLogVal)){
                                emailLogList.addAll(emailLogVal.split(CDdGDPRConstants.SEPARATOR));
                            }

                            for (string field : fieldsToCheck){
                                if(record.get(field) != oldMap.get(record.Id).get(field)){
                                    String oldEmail = (String) oldMap.get(record.Id).get(field);
                                    emailLogList.remove(oldEmail);
                                }
                            }
                            String emailOptOutLogVal = '';
                            if (emailLogList.size() > 0){
                                emailOptOutLogVal = String.join(new List<String>(emailLogList),
                                    CDdGDPRConstants.SEPARATOR);
                            }
                            record.put(emailFlds.emailOptOutLogField, emailOptOutLogVal);
                            record.put(emailFlds.emailOptOutField, (emailLogList.size() != 0));
                            if (emailFlds.isPersonAccount){
                                record.put(emailFlds.personEmailOptOutLogField, emailOptOutLogVal);
                                record.put(emailFlds.personEmailOptOutField, (emailLogList.size() != 0));
                            }
                        }
                    }
                }
            }
        }
    }

    public static void processCreateContactEvents(List<GDPR_Email_Action__e> ccEventList){
        List<CDdGDPREmailObj.CDdGDPRCreateContactObject> ccObjList = new List<CDdGDPREmailObj.CDdGDPRCreateContactObject>();

        for(GDPR_Email_Action__e event : ccEventList) {
            CDdGDPREmailObj.CDdGDPRCreateContactObject ccObj = new CDdGDPREmailObj.CDdGDPRCreateContactObject();
            ccObj.evt = event;
            Set<String> emailList = new Set<String>();
            SObject obj = (SObject) JSON.deserialize(event.JSON_Body__c, SObject.class);
            string emailids = (String)obj.get(event.Field_Name__c);
            if (String.isNotEmpty(emailIds)){
                emailList.addAll(emailids.split(';'));
            }

            if(emailList.size()>0){
                for(String emailId:emailList){
                    if (String.isNotBlank(emailId)){
                        ccObj.reqList.put(emailId,CDdGDPRCassieAPI.createCassieLookupRequest(emailId,event.Persona__c));
                    }
                }
                ccObjList.add(ccObj);
            }
        }

        String ccObjListString = JSON.serialize(ccObjList);
        sendCassieRequest(ccObjListString);
    }

    public static void updateRecords(List<CDdGDPREmailObj.CDdGDPRCreateContactObject> ccObjList){
        Map<Id, sObject> recordsToUpdate= new Map<Id, sObject>();

        for(CDdGDPREmailObj.CDdGDPRCreateContactObject wrp:ccObjList){
            SObject obj = (SObject) JSON.deserialize(wrp.evt.JSON_Body__c, SObject.class);
            String objName = CDdGDPREmailHelper.getObjectName(wrp.evt.Record_ID__c);
            CDdGDPREmailObj.CDdGDPREmailFields emailFlds = CDdGDPREmailHelper.getEmailFields(obj,objName);
            String emailLogVal = (String) obj.get(emailFlds.emailOptOutLogField);
            Set<String> emailLogList = new Set<String>();
            if (String.isNotBlank(emailLogVal)){
                emailLogList = new Set<String>(emailLogVal.split(CDdGDPRConstants.SEPARATOR));
            }
            Boolean emailOptOut = (Boolean) obj.get(emailFlds.emailOptOutField);
            for(String email:wrp.respList.keySet()){
                CDdGDPREmailObj.cassieCurrentPreferencesResponse resp = wrp.respList.get(email);
                Boolean optOut = false;
                for(CDdGDPREmailObj.CurrentPreferences cp:resp.CurrentPreferences){
                    if(cp.PreferenceValue != OPT_IN){
                       optOut = true;
                    }
                }
                if (optOut && !emailLogList.contains(email)){
                    emailLogList.add(email);
                } else if (!optOut  && emailLogList.contains(email)){
                    emailLogList.remove(email);
                }
            }

            obj.put(emailFlds.emailOptOutField, emailLogList.size() > 0);
            obj.put(emailFlds.emailOptOutLogField, String.join(new List<String>(emailLogList), CDdGDPRConstants.SEPARATOR));
            if (emailFlds.isPersonAccount){
                obj.put(emailFlds.personEmailOptOutField, emailLogList.size() > 0);
                obj.put(emailFlds.personEmailOptOutLogField, String.join(new List<String>(emailLogList), CDdGDPRConstants.SEPARATOR));
            }
            recordsToUpdate.put(obj.Id, obj);
        }

        if(!recordsToUpdate.isEmpty() && recordsToUpdate != NULL){
            CDdGDPREmailHelper.updateRecords(recordsToUpdate.values());
        }
    }
    /**
     * @author Nishant Sharda
     * @date 04/2023
     * @description: LEM-5360 Create an UUID value in the Mulesoft External Id field when Lemonade Record
     * id gets populated
     * @param newContact
     */
    public static void updateMuelsoftExtId(List<Contact> newContact){
        for(Contact con : newContact){
            if(string.isNotBlank(con.Lemonade_Record_ID__c ) && string.isBlank(con.Mulesoft_External_Id__c)){
                con.Mulesoft_External_Id__c = generateUUIDUtil.NewGuid();
            }
        }
    }

    @future (callout=true)
    private static void sendCassieRequest(String body) {
        List<CDdGDPREmailObj.CDdGDPRCreateContactObject> ccObjList =
                                        CDdGDPRCassieAPI.sendContactCreation(body);
        if (ccObjList.size() >0){
            updateRecords(ccObjList);
        }
    }
}