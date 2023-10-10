/**
* @author: Tia Xuan
* @date: 08-2021
* @description:  PII Helper
*/
public class CDdPIIHelper {
    public static final String DELETE_REQUEST_TYPE = 'BIZAPPS_FORGET';
    public static final String SQL_BEGIN = '   select Id ';
    public static final String SQL_FIELD_SEPARATOR = ' ,';
    public static final String SQL_FROM = '    from {0} ';
    public static final String SQL_WHERE = '   where {0} =: relationshipIds ';
    public static final String SQL_WHERE_USER_ID = '   where {0} =: userIds ';
    public static final String SQL_HISTORY = '   ,(select Id from Histories where {0})';
    public static final String SQL_HISTORY_CRITERIA = 'Field =  \'\'{0}\'\'';
    public static final String SQL_HISTORY_CRITERIA_SEPARATOR = ' OR ';
    public static final String BATCH_EMPTY_SQL = 'select Id from Account limit 0';
    public static final String HISTORY_OBJECT_NAME = 'Histories';
    public static final String PRIMARY_CUSTOMER_FIELD = ' , CustomerNo__pc ';
    public static final String PRIMARY_OBJECT_NAME = 'Account';
    public static final String PRIMARY_CUSTOMER_SQL_WHERE = ' where CustomerNo__pc =: psIds ';
    public static final String OBJECT_SEPERATOR = ';';
    public static final String NEW_STATUS = 'New';
    public static final String ERROR_STATUS = 'Error';
    public static final String COMPLETED_STATUS = 'Completed';
    public static final String DELETE_RECORD = 'Delete Record';
    public static final String AUDIT_FIELD_STRING = '{0} {1};';
    public static final String HISTORY_RECORD = 'History Record';
    public static final String DESCRIPTION_RECORD = '{0} : {1} : Fields : {2}';
    public static final String SQL_EQUALS_LABEL = 'Equals';
    public static final String SQL_CONTAINS_LABEL = 'Contains';
    public static final String SQL_EQUALS_VALUE_STRING = ' = \'\'{0}\'\'';
    public static final String SQL_CONTAINS_VALUE_STRING = ' LIKE \'\'%{0}%\'\'';
    public static final String SQL_EQUALS_VALUE_OTHER = ' = {0}';
    public static final String SQL_NUMBER_FIELD_DATATYPE = 'Number';
    public static final String SQL_DATE_FIELD_DATATYPE = 'Date';
    public static final String SQL_WHERE_AND = ' AND ';
    public static final String EMPTY_STRING = '';
    public static final String DELETE_FIELD_VALUE = 'Delete';
    public static final String MASK_FIELD_VALUE = 'Mask';
    public static final String ADDRESS_DATA_TYPE = 'Address';
    public static final Map<String,String> ADDRESS_FIELD_MAP = new Map<String, String>{'Street' => 'Text', 'State' => 'Text', 'City' => 'Text', 'PostalCode' => 'Text', 'Country' => 'Text', 'Latitude' => 'Number', 'Longitude' => 'Number'};
    public static final String NAME_DATA_TYPE = 'Name';
    public static final Map<String,String> NAME_FIELD_MAP = new Map<String, String>{'FirstName'=> 'Text', 'LastName'=> 'Text'};
    public static final Map<String,Object> FIELD_TYPE_MASK_MAP = new Map<String, Object>{   'Text'=> 'xxx',
                                                                                            'Email'=> '@forgotten.doordash.com',
                                                                                            'Number'=> 0,
                                                                                            'Date'=> Date.newInstance(1900, 1, 1),
                                                                                            'DateTime'=> DateTime.newInstance(1900, 1, 1)};

    public static Support_Settings__c SUPPORT_SETTINGS = Support_Settings__c.getInstance() == null ?  new Support_Settings__c() : Support_Settings__c.getInstance();
    public static final String DUPLICATE_ENTRY = 'Duplicate Entry';

    //BIZS-954 limit records for bulk operation
    public static Decimal PST_BULK_LIMIT = SUPPORT_SETTINGS.Max_RTF_Bulk_Entries__c != null ? SUPPORT_SETTINGS.Max_RTF_Bulk_Entries__c : 200;
    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    public static Map<Double, String> getAccountIds(List<Privacy_Service__c> psList){
        Map<Double, String> retVal = new Map<Double, String>();
        for (Privacy_Service__c ps : psList){
            retVal.put(ps.User_Id__c, '');
        }

        String sqlString = SQL_BEGIN;
        sqlString += PRIMARY_CUSTOMER_FIELD;
        sqlString += String.format(SQL_FROM, new List<String>{PRIMARY_OBJECT_NAME});
        sqlString += PRIMARY_CUSTOMER_SQL_WHERE;

        List<Double> psIds = new List<Double>(retVal.keySet());

        List<Account> accList = Database.query(sqlString);
        for (Account acc : accList){
            if (retVal.containsKey(acc.CustomerNo__pc)){
                String accIds = retVal.get(acc.CustomerNo__pc);
                if (String.isBlank(accIds)){
                    accIds = acc.Id;
                } else {
                    accIds += ';' + acc.Id;
                }
                retVal.put(acc.CustomerNo__pc, accIds);
            }
        }

        return retVal;
    }

    public static String formSOQLString(PIIWrapper config, Privacy_Service__c ps){
        String sqlString = '';
        if (ps.Action_ID__c == DELETE_REQUEST_TYPE){
            sqlString += SQL_BEGIN;
            if (String.isNotBlank(config.relFieldName) && config.objName != PRIMARY_OBJECT_NAME){
                sqlString += SQL_FIELD_SEPARATOR + config.relFieldName;
            }
            if (!config.objDelete){
                List<PIIFieldWrapper> flds = config.flds;
                for (PIIFieldWrapper fld : flds){
                    sqlString += SQL_FIELD_SEPARATOR + fld.fieldName;
                }

                List<String> historyFields = new List<String>();
                for (PIIFieldWrapper fld : flds){
                    if (fld.isHistoryTracking){
                        historyFields.add(String.format(SQL_HISTORY_CRITERIA, new List<String>{fld.fieldName}));
                    }
                }

                if (historyFields.size() > 0){
                    String historyCriteria = String.join(historyFields, SQL_HISTORY_CRITERIA_SEPARATOR);
                    sqlString += String.format(SQL_HISTORY, new List<String>{historyCriteria});
                }
            }

            sqlString += String.format(SQL_FROM, new List<String>{config.objName});
            if (String.isNotBlank(config.relFieldName)){
                if (config.useUserId){
                    sqlString += String.format(SQL_WHERE_USER_ID, new List<String>{config.relFieldName});
                } else {
                    sqlString += String.format(SQL_WHERE, new List<String>{config.relFieldName});
                }
            }

            List<String> fltList = new List<String>();
            for (Privacy_Config_Filter__mdt filter : config.filters){
                String fltString = filter.Field_Name__r.QualifiedApiName;
                Boolean isNumber = false;
                Boolean isDate = false;
                if (filter.Field_Name__r.DataType.contains(SQL_NUMBER_FIELD_DATATYPE)){
                    isNumber = true;
                }
                if (filter.Field_Name__r.DataType.contains(SQL_DATE_FIELD_DATATYPE)){
                    isDate = true;
                }
                if (filter.Compare_Type__c == SQL_EQUALS_LABEL){
                    if (isNumber || isDate){
                        fltString += String.format(SQL_EQUALS_VALUE_OTHER, new List<String>{filter.Field_Value__c});
                    } else {
                        fltString += String.format(SQL_EQUALS_VALUE_STRING, new List<String>{filter.Field_Value__c});
                    }
                } else if (filter.Compare_Type__c == SQL_CONTAINS_LABEL){
                    if (isNumber || isDate){
                        fltString = EMPTY_STRING;
                    } else {
                        fltString += String.format(SQL_CONTAINS_VALUE_STRING, new List<String>{filter.Field_Value__c});
                    }
                }
                if (String.isNotBlank(fltString)){
                    fltList.add(fltString);
                }
            }

            if (fltList.size() > 0){
                sqlString += SQL_WHERE_AND;
                sqlString += String.join(fltList, SQL_WHERE_AND);
            }
        }
        return sqlString;
    }

    public static List<PIIWrapper> getPrivacyConfigs(String customerType){

        Map<String, PIIWrapper> retValMap = new Map<String,PIIWrapper>();

        List<Privacy_Config_Filter__mdt> filters =  [select Object_Name__r.QualifiedApiName,
                                                            Field_Name__c,
                                                            Field_Name__r.QualifiedApiName,
                                                            Field_Name__r.DataType,
                                                            Customer_Type__c,
                                                            Compare_Type__c,
                                                            Field_Value__c
                                                    from Privacy_Config_Filter__mdt
                                                    where Is_Active__c = true
                                                        and Customer_Type__c =: customerType];
        Map<String, List<Privacy_Config_Filter__mdt>> filterMap = new Map<String,List<Privacy_Config_Filter__mdt>>();
        for (Privacy_Config_Filter__mdt flt : filters){
            if (filterMap.containsKey(flt.Object_Name__r.QualifiedApiName)){
                List<Privacy_Config_Filter__mdt> fltList = filterMap.get(flt.Object_Name__r.QualifiedApiName);
                fltList.add(flt);
                filterMap.put(flt.Object_Name__r.QualifiedApiName, fltList);
            } else {
                filterMap.put(flt.Object_Name__r.QualifiedApiName, new List<Privacy_Config_Filter__mdt>{flt});
            }
        }

        List<Privacy_Config__mdt> configs = [select Object_Name__r.QualifiedApiName,
                                                    Field_Name__c,
                                                    Field_Name__r.QualifiedApiName,
                                                    Field_Name__r.IsFieldHistoryTracked,
                                                    Field_Name__r.DataType,
                                                    Action_Type__c,
                                                    Customer_Type__c,
                                                    Relationship_Field__c,
                                                    Object_Delete__c,
                                                    Use_User_ID__c
                                            from Privacy_Config__mdt
                                            where Is_Active__c = true
                                                and Customer_Type__c =: customerType];
        for (Privacy_Config__mdt cfg : configs){
            PIIWrapper wrp = new PIIWrapper();
            wrp.objName = cfg.Object_Name__r.QualifiedApiName;
            wrp.objDelete = cfg.Object_Delete__c;
            wrp.useUserId = cfg.Use_User_ID__c;
            wrp.relFieldName = cfg.Relationship_Field__c;
            if (filterMap.containsKey(wrp.objName)){
                wrp.filters = filterMap.get(wrp.objName);
            }

            if (retValMap.containsKey(wrp.objName)){
                wrp = retValMap.get(wrp.objName);
            }

            if (cfg.Field_Name__c != null
                    && cfg.Field_Name__r.DataType == ADDRESS_DATA_TYPE){
                String fldOrig = cfg.Field_Name__r.QualifiedApiName;
                for (String aField : ADDRESS_FIELD_MAP.keySet()){
                    String fld = fldOrig.replace(ADDRESS_DATA_TYPE, aField);
                    PIIFieldWrapper wrpFld = new PIIFieldWrapper();
                    wrpFld.objName = wrp.objName;
                    wrpFld.config = cfg;
                    if (!cfg.Object_Delete__c){
                        wrpFld.fieldName = fld;
                        wrpFld.isHistoryTracking = cfg.Field_Name__r.IsFieldHistoryTracked;
                        wrpFld.dataType = ADDRESS_FIELD_MAP.get(aField);
                        wrpFld.maskType = cfg.Action_Type__c;
                    }
                    wrp.flds.add(wrpFld);
                }
            } else if ( cfg.Field_Name__c != null
                            && cfg.Field_Name__r.DataType == NAME_DATA_TYPE) {
                for (String aField : NAME_FIELD_MAP.keySet()){
                    PIIFieldWrapper wrpFld = new PIIFieldWrapper();
                    wrpFld.objName = wrp.objName;
                    wrpFld.config = cfg;
                    if (!cfg.Object_Delete__c){
                        wrpFld.fieldName = aField;
                        wrpFld.isHistoryTracking = cfg.Field_Name__r.IsFieldHistoryTracked;
                        wrpFld.dataType = NAME_FIELD_MAP.get(aField);
                        wrpFld.maskType = cfg.Action_Type__c;
                    }
                    wrp.flds.add(wrpFld);
                }
            } else {
                PIIFieldWrapper wrpFld = new PIIFieldWrapper();
                wrpFld.objName = wrp.objName;
                wrpFld.config = cfg;
                if (!cfg.Object_Delete__c){
                    wrpFld.fieldName = cfg.Field_Name__r.QualifiedApiName;
                    wrpFld.isHistoryTracking = cfg.Field_Name__r.IsFieldHistoryTracked;
                    wrpFld.dataType = cfg.Field_Name__r.DataType;
                    wrpFld.maskType = cfg.Action_Type__c;
                }
                wrp.flds.add(wrpFld);
            }
            retValMap.put(wrp.objName, wrp);
        }
        return retValMap.values();
    }

    public static PIIWrapper getPrivacyConfigsByObject(String objName, String customerType){
        List<PIIWrapper> wrpList = getPrivacyConfigs(customerType);
        for (PIIWrapper wrp : wrpList){
            if (wrp.objName == objName){
                return wrp;
            }
        }
        return null;
    }

    public static PIIMaskResponse maskData(PIIWrapper wrp, SObject obj, Privacy_Service_Task__c pst){
        PIIMaskResponse retVal = new PIIMaskResponse(wrp.objName);
        try{
            if (wrp.objDelete){
                retVal.msg = DELETE_RECORD;
            } else {
                retVal.objCopy.Id = obj.Id;
                for (PIIFieldWrapper fwrp : wrp.flds){
                    if (fwrp.maskType == DELETE_FIELD_VALUE){
                        retVal.objCopy.put(fwrp.fieldName, null);
                    } else {
                        Object val = maskDataByType(fwrp,pst);
                        retVal.objCopy.put(fwrp.fieldName, val);
                    }
                    retVal.msg += String.format(AUDIT_FIELD_STRING, new List<String>{fwrp.fieldName, fwrp.maskType});
                }
            }
        } catch (Exception e){
            retVal.isSuccess = false;
            retVal.msg = e.getMessage();
        }
        return retVal;
    }

    public static Object maskDataByType(PIIFieldWrapper fwrp, Privacy_Service_Task__c pst){
        for (String fType : FIELD_TYPE_MASK_MAP.keySet()){
            Object objVal = FIELD_TYPE_MASK_MAP.get(fType);
            if (fwrp.dataType.contains(fType)){
                if(fwrp.dataType == 'Email' && pst != null && String.isNotEmpty(pst.Privacy_Service__r.Request_ID__c)){
                    String requestID =  pst.Privacy_Service__r.Request_ID__c;
                    objVal = requestID + objVal;
                }else if(fwrp.dataType == 'Email' && (pst == null || (pst != null && String.isEmpty(pst.Privacy_Service__r.Request_ID__c)))){
                    objVal = 'xxx@unknownrequest.doordash.com';
                }
                return objVal;
            }
        }
        return EMPTY_STRING;
    }

    public static List<GDPR_Response__e> createPrivacyPE(List<Id> psIdList){
        List<GDPR_Response__e> gdprEventList = new List<GDPR_Response__e>();
        if (psIdList.size() > 0){
            List<Privacy_Service_Task__c> pstAllList = [select  Id,
                                                                Status__c,
                                                                Privacy_Service__c,
                                                                Privacy_Service__r.Request_ID__c,
                                                                (select Id,
                                                                        Has_Error__c,
                                                                        Description__c
                                                                from Privacy_Service_Task_Items__r)
                                                        from Privacy_Service_Task__c
                                                        where Privacy_Service__c =: psIdList];

            Set<Id> psNewList = new Set<Id>();
            Map<Id, String> psToRequestId = new Map<Id, String>();
            Map<Id, List<Privacy_Service_Task__c>> psMap = new Map<Id, List<Privacy_Service_Task__c>>();
            for (Privacy_Service_Task__c pst : pstAllList){
                psToRequestId.put(pst.Privacy_Service__c, pst.Privacy_Service__r.Request_ID__c);
                if (pst.Status__c == CDdPIIHelper.NEW_STATUS){
                    psNewList.add(pst.Privacy_Service__c);
                } else {
                    List<Privacy_Service_Task__c> taskList = new List<Privacy_Service_Task__c>{pst};
                    if (psMap.containsKey(pst.Privacy_Service__c)){
                        taskList = psMap.get(pst.Privacy_Service__c);
                        taskList.add(pst);
                    }
                    psMap.put(pst.Privacy_Service__c, taskList);
                }
            }

            for (String psId : psMap.keySet()){
                if (!psNewList.contains(psId)){
                    Boolean hasError = false;
                    GDPR_Response__e evt = new GDPR_Response__e();
                    evt.Request_ID__c = psToRequestId.get(psId);
                    for (Privacy_Service_Task__c tsk : psMap.get(psId)){
                        if (tsk.Status__c == CDdPIIHelper.ERROR_STATUS){
                            hasError = true;
                            evt.Status__c = CDdPIIHelper.ERROR_STATUS;
                            evt.Message__c = '';
                            for (Privacy_Service_Task_Item__c psti : tsk.Privacy_Service_Task_Items__r){
                                if (psti.Has_Error__c){
                                    evt.Message__c += psti.Description__c;
                                }
                            }
                        }
                    }
                    if (!hasError){
                        evt.Status__c = CDdPIIHelper.COMPLETED_STATUS;
                    }
                    gdprEventList.add(evt);
                }
            }
        }
        return gdprEventList;
    }

    public class PIIWrapper{
        public String objName                           { get; set; }
        public Boolean objDelete                        { get; set; }
        public Boolean useUserId                        { get; set; }
        public String relFieldName                      { get; set; }
        public List<Privacy_Config_Filter__mdt> filters { get; set; }
        public List<PIIFieldWrapper> flds               { get; set; }

        public PIIWrapper(){
            flds = new List<PIIFieldWrapper>();
            filters = new List<Privacy_Config_Filter__mdt>();
        }
    }

    public class PIIFieldWrapper{
        public String objName                   { get; set; }
        public String fieldName                 { get; set; }
        public Boolean isHistoryTracking        { get; set; }
        public String dataType                  { get; set; }
        public String maskType                  { get; set; }
        public Privacy_Config__mdt config       { get; set; }
    }

    public class PIIMaskResponse{
        public Boolean isSuccess    { get; set; }
        public String msg           { get; set; }
        public SObject objCopy      { get; set; }

        public PIIMaskResponse(String objName){
            isSuccess = true;
            msg = EMPTY_STRING;
            objCopy = CDdPIIHelper.SOBJECT_TYPES.get(objName).newSObject();
        }
    }

}