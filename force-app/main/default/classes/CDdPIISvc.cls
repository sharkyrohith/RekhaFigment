/**
* @author: Tia Xuan
* @date: 08-2021
* @description:  PII service
*/
public class CDdPIISvc {

    public static void processPrivacyService(String psListString){
        List<Privacy_Service__c> psList = (List<Privacy_Service__c>) JSON.deserialize(psListString, List<Privacy_Service__c>.class);
        Map<Double, String> accountIdMap = CDdPIIHelper.getAccountIds(psList);
        List<Privacy_Service_Task__c> tasks = new List<Privacy_Service_Task__c>();
        for (Privacy_Service__c ps : psList){
            List<CDdPIIHelper.PIIWrapper> pConfigs = CDdPIIHelper.getPrivacyConfigs(ps.Profile_Type__c);
            for (CDdPIIHelper.PIIWrapper config: pConfigs){
                Privacy_Service_Task__c tsk = new Privacy_Service_Task__c();
                tsk.Object_Name__c = config.objName;
                tsk.Customer_Type__c = ps.Profile_Type__c;
                tsk.Privacy_Service__c = ps.Id;
                tsk.Query__c = CDdPIIHelper.formSOQLString(config, ps);
                tsk.Status__c = CDdPIIHelper.NEW_STATUS;
                if (accountIdMap.containsKey(ps.User_Id__c)){
                    tsk.Relationship_IDs__c = accountIdMap.get(ps.User_Id__c);
                }
                tasks.add(tsk);
            }
        }
        insert tasks;
    }

    public static void respondAfterTreatment(List<Privacy_Service_Task__c> pstList){
        List<Id> psIdList = new List<Id>();
        for (Privacy_Service_Task__c pst : pstList){
            if (pst.Status__c != CDdPIIHelper.NEW_STATUS){
                psIdList.add(pst.Privacy_Service__c);
            }
        }

        if (psIdList.size() > 0){

            List<GDPR_Response__e> gdprEventList = CDdPIIHelper.createPrivacyPE(psIdList);
            List<Privacy_Service_Task__c> pstAllList = [select  Id, 
                                                                Status__c,
                                                                Privacy_Service__c
                                                        from Privacy_Service_Task__c
                                                        where Privacy_Service__c =: psIdList];
            
            Set<Id> psNewList = new Set<Id>();
            Map<Id, List<Privacy_Service_Task__c>> psMap = new Map<Id, List<Privacy_Service_Task__c>>();
            for (Privacy_Service_Task__c pst : pstAllList){
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

            List<Privacy_Service__c> psToUpdate = new List<Privacy_Service__c>();
            for (String psId : psMap.keySet()){
                if (!psNewList.contains(psId)){
                    Privacy_Service__c ps = new Privacy_Service__c();
                    ps.Id = psId;
                    Boolean hasError = false;
                    for (Privacy_Service_Task__c tsk : psMap.get(psId)){
                        if (tsk.Status__c == CDdPIIHelper.ERROR_STATUS){
                            hasError = true;
                            ps.Status__c = CDdPIIHelper.ERROR_STATUS;
                        }
                    }
                    if (!hasError){
                        ps.Status__c = CDdPIIHelper.COMPLETED_STATUS;
                    }
                    psToUpdate.add(ps);
                }
            }

            if (psToUpdate.size() > 0){
                Database.update(psToUpdate, true);
            }

            if (gdprEventList.size() > 0){
                EventBus.publish(gdprEventList);
            }


        }
    }

    public static void treatDuplicatePS(List<Privacy_Service__c> psList){
        List<String> requestIdList = new List<String>();
        for (Privacy_Service__c ps : psList){
            if (String.isNotBlank(ps.Request_ID__c)){
                requestIdList.add(ps.Request_ID__c);
            }
        }

        List<Privacy_Service__c> pList = [  select  Id,
                                                    Request_ID__c,
                                                    Status__c
                                            from Privacy_Service__c
                                            where Request_ID__c =: requestIdList];
        Map<String, Privacy_Service__c> existingReqs = new Map<String, Privacy_Service__c>();
        for (Privacy_Service__c ps : pList){
            existingReqs.put(ps.Request_ID__c, ps);
        }

        List<String> peToResendList = new List<String>();
        for (Privacy_Service__c ps : psList){
            if (String.isNotBlank(ps.Request_ID__c)
                && existingReqs.containsKey(ps.Request_ID__c)){
                    Privacy_Service__c oldPS = existingReqs.get(ps.Request_ID__c);
                    if (oldPS.Status__c != CDdPIIHelper.NEW_STATUS){
                        peToResendList.add(oldPS.Id);
                    } 
                    ps.addError(CDdPIIHelper.DUPLICATE_ENTRY);

            }
        }
        
        if (peToResendList.size() > 0){
            List<GDPR_Response__e> gdprEventList = CDdPIIHelper.createPrivacyPE(peToResendList);
            if (gdprEventList.size() > 0){
                EventBus.publish(gdprEventList);
            }

        }

    }
}