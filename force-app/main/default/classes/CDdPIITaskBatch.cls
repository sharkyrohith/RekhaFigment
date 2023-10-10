/**
* @author: Tia Xuan
* @date: 08-2021
* @description:  PII Task Batch
*/
public class CDdPIITaskBatch implements Database.Batchable<SObject>, Database.Stateful{

    public Map<Id, Privacy_Service_Task__c> pstMap;
    public List<Privacy_Service_Task__c> pstList;
    public CDdPIIHelper.PIIWrapper wrp;
    public String qry;
    public Map<Id, Boolean> errorMap = new Map<Id, Boolean>();

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String newStatus = CDdPIIHelper.NEW_STATUS;
        List<Privacy_Service_Task__c> pstObjList = [ select Object_Name__c,
                                                            Customer_Type__c
                                                    from    Privacy_Service_Task__c
                                                    where   Status__c =: newStatus
                                                    order by LastModifiedDate ASC
                                                    limit 1];

        if (pstObjList.size() > 0){  
            pstMap = new Map<Id, Privacy_Service_Task__c>();
            String objName = pstObjList[0].Object_Name__c;     
            String customerType = pstObjList[0].Customer_Type__c;
            
            //BIZS-954 limit records for bulk operation
            Integer pstLimit = Integer.valueOf(CDdPIIHelper.PST_BULK_LIMIT);                                           
            pstList =   [select Id,
                                Relationship_IDs__c,                        
                                Name,
                                Object_Name__c,
                                Privacy_Service__c,
                                Privacy_Service__r.User_ID__c,
                         		Privacy_Service__r.Request_ID__c,
                                Customer_Type__c,
                                Query__c,
                                Status__c,
                                Retries__c
                        from    Privacy_Service_Task__c
                        where   Object_Name__c = : objName
                                and Customer_Type__c =: customerType
                                and Status__c =: newStatus
                        order by LastModifiedDate ASC
                        limit: pstLimit];
        
            Privacy_Service_Task__c pst = pstList[0];
            wrp = CDdPIIHelper.getPrivacyConfigsByObject(pst.Object_Name__c, pst.Customer_Type__c);
            qry = pst.Query__c;
            Set<String> relationshipIds = new Set<String>();
            Set<Decimal> userIds = new Set<Decimal>();
            for (Privacy_Service_Task__c p : pstList){
                if (String.isNotBlank(p.Relationship_IDs__c)){
                    List<String> relIdList = p.Relationship_IDs__c.split(CDdPIIHelper.OBJECT_SEPERATOR);
                    for (String relId : relIdList){
                        pstMap.put(relId, p);
                        relationshipIds.add(relId);
                    }
                }
                if (p.Privacy_Service__r.User_ID__c != null){
                    userIds.add(p.Privacy_Service__r.User_ID__c);
                }
            }

            if (relationshipIds.size() == 0){
                qry = CDdPIIHelper.BATCH_EMPTY_SQL;
            }
            
        } else {
            qry = CDdPIIHelper.BATCH_EMPTY_SQL;
        }

        return Database.getQueryLocator(qry);
    }
    
    /** 
    * @description execute batch to treat PII data
    */  
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Map<String, Privacy_Service_Task_Item__c> privacyItems = new Map<String, Privacy_Service_Task_Item__c>();
        List<SObject> objToUpsert = new List<SObject>();
        List<SObject> objToDelete = new List<SObject>();
        Savepoint sp = Database.setSavepoint();
        try {
            for (SObject obj : scope){
                String relId = (String) obj.get(wrp.relFieldName);
                Privacy_Service_Task__c pst = pstMap.containsKey(relId) ? pstMap.get(relId) : null;
                CDdPIIHelper.PIIMaskResponse resp = CDdPIIHelper.maskData(wrp, obj, pst);
                errorMap.put(pst.Id, !resp.isSuccess);
                Privacy_Service_Task_Item__c item = new Privacy_Service_Task_Item__c();
                item.Has_Error__c = false;
                item.Object_Name__c = wrp.objName;
                item.Privacy_Service_Task__c = pst.Id;
                item.Object_ID__c = obj.Id;
                item.Description__c = resp.msg;
                privacyItems.put(obj.Id, item);
                if (resp.isSuccess){
                    if (wrp.objDelete){
                        objToDelete.add(obj);
                    } else {
                        objToUpsert.add(resp.objCopy);
                    }
                }
                
                if (Test.isRunningTest() || obj.getPopulatedFieldsAsMap().containsKey(CDdPIIHelper.HISTORY_OBJECT_NAME)){
                    List<SObject> hObjs = new List<SObject>();
                    if (Test.isRunningTest()){
                        hObjs.add(new Account());
                    } else {
                        hObjs  = obj.getSObjects(CDdPIIHelper.HISTORY_OBJECT_NAME);
                    }
                    for (SObject hObj : hObjs){
                        String hObjId = Test.isRunningTest() ? 'test' : hObj.Id ;
                        Privacy_Service_Task_Item__c hItem = new Privacy_Service_Task_Item__c();
                        hItem.Has_Error__c = false;
                        hItem.Object_Name__c = wrp.objName;
                        hItem.Privacy_Service_Task__c = pst.Id;
                        hItem.Object_ID__c = hObjId;
                        hItem.Description__c = CDdPIIHelper.HISTORY_RECORD;              
                        privacyItems.put(hObjId, hItem);
                        if (!Test.isRunningTest()){ 
                            objToDelete.add(hObj);
                        }
                    }
                }
            }

            if (objToUpsert.size() > 0){
                List<Database.UpsertResult> uResults = Database.upsert(objToUpsert, true);
                for(Database.UpsertResult ur : uResults) {
                    if(ur.isSuccess()){
                        continue;
                    }
                    Privacy_Service_Task_Item__c psti = privacyItems.get(ur.getId());
                    psti.Description__c = CDdPIIHelper.EMPTY_STRING;
                    errorMap.put(psti.Privacy_Service_Task__c, true);
                    for(Database.Error err : ur.getErrors()) {
                        psti.Has_Error__c = true;
                        psti.Description__c +=  String.format(CDdPIIHelper.DESCRIPTION_RECORD, new List<String>{String.valueOf(err.getStatusCode()), err.getMessage(), String.valueOf(err.getFields())}); 
                    }
                } 
            } 

            if (objToDelete.size() > 0){
                List<Database.DeleteResult> dResults = Database.delete(objToDelete, true);
                for(Database.DeleteResult dr : dResults) {
                    if(dr.isSuccess()){
                        continue;
                    }
                    Privacy_Service_Task_Item__c psti = privacyItems.get(dr.getId());
                    psti.Description__c = CDdPIIHelper.EMPTY_STRING;
                    errorMap.put(psti.Privacy_Service_Task__c, true);
                    for(Database.Error err : dr.getErrors()) {
                        psti.Has_Error__c = true;
                        psti.Description__c +=  String.format(CDdPIIHelper.DESCRIPTION_RECORD, new List<String>{String.valueOf(err.getStatusCode()), err.getMessage(), String.valueOf(err.getFields())}); 
                    }
                } 
            } 

            
        } catch (Exception e){
            Database.rollback(sp);
            for (String piKey : privacyItems.keySet()){
                Privacy_Service_Task_Item__c item = privacyItems.get(piKey);
                errorMap.put(item.Privacy_Service_Task__c, true);
                item.Has_Error__c = true;
                item.Description__c = e.getMessage();
            }
        } finally {
            if (privacyItems.size() > 0){
                Database.insert(privacyItems.values(), true);
            } 
        }
    }

    /** 
    * @description Finish the batch operation
    */  
    public void finish(Database.BatchableContext BC) {
        if (pstList != null && pstList.size() > 0){
            for (Privacy_Service_Task__c pst : pstList){
                Boolean hasError = errorMap.containsKey(pst.Id)? errorMap.get(pst.Id): false;
                if (hasError){
                    if (pst.Retries__c == null){
                        pst.Retries__c = 0;
                    }
                    Decimal maxRetries = CDdPIIHelper.SUPPORT_SETTINGS.Max_RTF_Retries__c != null ? CDdPIIHelper.SUPPORT_SETTINGS.Max_RTF_Retries__c : 0;
                    if (pst.Retries__c < maxRetries){
                        pst.Retries__c += 1;
                    } else {
                        pst.Status__c = CDdPIIHelper.ERROR_STATUS;
                    }
                } else {
                    pst.Status__c = CDdPIIHelper.COMPLETED_STATUS;
                }
            }
            Database.update(pstList, true);
        }
    }
}