/**
 * @author      Sahil Chaudhry
 * @date        Dec 2021
 * @decription  BIZS-814 - LiveChatTranscript Trigger Helper
 *
 */
public with sharing class CDdLiveChatTransTriggerHelper {
    
   
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    private static final String LABEL_COMPLETED = 'Completed';
    private static final String LABEL_SERVED_CHAT = 'Served Chat';
    /*****************************************************************************************************************************
     *
     * Public Methods
     *
    *****************************************************************************************************************************/    
    /**
    * @description  Determines if a field has been updated on the record
    * @param   LiveChatTranscript newLct - LCT in trigger.new
    *          Map<Id, LiveChatTranscript> oldMap - trigger.oldMap
    *          String fieldName - field to check if it has been updated
    * @return  Boolean
    */
    public static Boolean isFieldUpdated(LiveChatTranscript newLct, Map<Id, LiveChatTranscript> oldMap, String fieldName) {
        return (oldMap != null && newLct.get(fieldName) != oldMap.get(newLct.Id).get(fieldName));
    }
   
    /**
    * @description  Determines if the record is a new record or if a field has been updated on the record
    * @param   LiveChatTranscript newLct - LCT in trigger.new
    *          Map<Id, LiveChatTranscript> oldMap - trigger.oldMap
    *          String fieldName - field to check if it has been updated
    * @return  Boolean
    */
    public static Boolean isNewOrFieldUpdated(LiveChatTranscript newLct, Map<Id, LiveChatTranscript> oldMap, String fieldName) { 
        return trigger.isInsert || isFieldUpdated(newLct,oldMap,fieldName);
    }

    /**
     *  @author: Tia Xuan
     *  @date: 2020-08
     *  @description BZAPSUP-732 --- Populate Pre-chat Info on Chat Transcript and Update Case for Community Chats
    */
    public static void associateChatIds(list<LiveChatTranscript> newList, Map<Id, LiveChatTranscript> oldMap){
        List<String> emailList = new List<String>();
        List<LiveChatTranscript> affectedTranscripts = new List<LiveChatTranscript>();
        for (LiveChatTranscript trans : newList){
            if (trans.Channel__c == 'Consumer Community'
                && String.isBlank(trans.CustomerName__c)){
                trans.CustomerName__c =  trans.Chat_First_Name__c + ' ' + trans.Chat_Last_Name__c ;
            } else if (trans.Channel__c == 'Dasher Community'
                        && String.isBlank(trans.DasherName__c)){
                trans.DasherName__c =  trans.Chat_First_Name__c + ' ' + trans.Chat_Last_Name__c ;
            }
            if (trans.Status == 'Missed'){
                if ( (String.isNotBlank(trans.CustomerEmail__c)
                        || String.isNotBlank(trans.DasherEmail__c))
                    && (trans.CustomerNo__c == null
                        || trans.DasherNo__c == null)){
                    if (String.isNotBlank(trans.CustomerEmail__c)){
                        emailList.add(trans.CustomerEmail__c);
                    } else if (String.isNotBlank(trans.DasherEmail__c)){
                        emailList.add(trans.DasherEmail__c);
                    }
                    affectedTranscripts.add(trans);
                }
            }
        }

        if (emailList.size() > 0){
            List<Contact> ctcList = [select Id,
                                            Email,
                                            Phone,
                                            CustomerNo__c,
                                            DasherNo__c,
                                            IsPersonAccount
                                    from Contact
                                    where email =: emailList
                                    ORDER BY LastModifiedDate DESC];
            Map<String, List<Contact>> emailContacts = new Map<String, List<Contact>>();
            for (Contact ctc : ctcList){
                if (!emailContacts.containsKey(ctc.Email)){
                    emailContacts.put(ctc.Email, new List<Contact>{ctc});
                } else {
                    List<Contact> ctcs = emailContacts.get(ctc.Email);
                    ctcs.add(ctc);
                    emailContacts.put(ctc.Email, ctcs);
                }
            }

            if (emailContacts.size() > 0){
                for (LiveChatTranscript trans : affectedTranscripts){
                    List<Contact> ctcs = new List<Contact>();
                    if (String.isNotBlank(trans.CustomerEmail__c)
                        && emailContacts.containsKey(trans.CustomerEmail__c)){
                        ctcs = emailContacts.get(trans.CustomerEmail__c);
                        for (Contact c : ctcs){
                            if (c.CustomerNo__c != null
                                && trans.CustomerNo__c == null){
                                trans.CustomerNo__c = c.CustomerNo__c;
                            }
                        }
                    } else if (String.isNotBlank(trans.DasherEmail__c)
                                && emailContacts.containsKey(trans.DasherEmail__c)){
                        ctcs = emailContacts.get(trans.DasherEmail__c);
                        for (Contact c : ctcs){
                            if (c.DasherNo__c != null
                                && trans.DasherNo__c == null){
                                trans.DasherNo__c = c.DasherNo__c;
                            }
                        }
                    }
                }
            }
        }
    }

    /** 
    * @author     Sahil Chaudhry
    * @date       12/2021
    * @decription BIZS-814 populate cases with chat transcript duration and wait time
    * @param      trigger.newList and oldMap   
    * @return     None
    */
    public static void populateTimesOnCases(Map<Id, LiveChatTranscript> newMap, Map<Id, LiveChatTranscript> oldMap) {
        if (CDdExperimentSvc.getSupportFeatureFlag('Disable_Old_Transcript_Method__c')){
            return;
        }
        Set<Id> scriptCaseIds = new Set<Id>();
        Set<Id> scriptOldCaseIds = new Set<Id>();
        List<Case> caseUpdateList = new List<Case>();
        for (LiveChatTranscript transcript : newMap.values()) {
            if(transcript.Status==LABEL_COMPLETED && transcript.caseId != null
                && isNewOrFieldUpdated(transcript, oldMap, 'Status')) {
                scriptCaseIds.add(transcript.caseId);
            }
            if (oldMap != null && oldMap.get(transcript.Id).Status==LABEL_COMPLETED
                && oldMap.get(transcript.Id).caseId != null
                && oldMap.get(transcript.Id).caseId != newMap.get(transcript.Id).caseId) {
                scriptOldCaseIds.add(transcript.caseId);
            }
        }
        if (!scriptCaseIds.isEmpty() || !scriptOldCaseIds.isEmpty()) {
            for(AggregateResult result: [SELECT CaseId, sum(WaitTime) WaitTime, sum(ChatDuration) Duration
                                            FROM LiveChatTranscript 
                                            WHERE (CaseId in :scriptCaseIds AND Case.CreatedDate >= YESTERDAY)
                                            OR (CaseId in :scriptOldCaseIds)
                                            GROUP BY CaseId]) {
                Id caseId = (Id)result.get('CaseId');
                Map<String,Object> fieldVal = new Map<String,Object>{
                                                'ChatWaitTime__c' => (Decimal)(result.get('WaitTime')),
                                                'ChatDuration__c' => (Decimal)(result.get('Duration')),
                                                'Chat_Type__c' => LABEL_SERVED_CHAT
                };
                CDdLiveChatTransOptimizationHelper.setSobjectToUpdate(CDdSupportConstants.CASE_OBJECT_LABEL,
                                                                        caseId,fieldVal);
            }
        }
    }

    /** 
    * @author     Sahil Chaudhry
    * @date       12/2021
    * @decription BIZS-814 stamp the previous queue on the case (optimized)
    * @param      trigger.newList and oldMap   
    * @return     None
    */
    public static void populatePreviousQueue(List<LiveChatTranscript> newList, Map<Id,LiveChatTranscript> oldMap) {
        Map<Id,Case> relatedCasesMap = CDdLiveChatTransOptimizationHelper.getCaseMap();//get from memory
        Set<Id> ownerIds = new Set<Id>();
        List<LiveChatTranscript> lctToProcess = new List<LiveChatTranscript>();
        Map<Id,Id> lctToQueueIdMap = new Map<Id,Id>();
        //list of most recent owners of the chat transcript from history table as its not possible
        // to get previous owner from trigger.old (omni routed work item doesnt have that info)
        List<LiveChatTranscriptHistory> transHistoryList = [SELECT LiveChatTranscriptId, OldValue 
                                                            FROM LiveChatTranscriptHistory
                                                            WHERE LiveChatTranscriptId =: newList
                                                            AND Field = 'Owner'
                                                            ORDER BY CreatedDate DESC];
        //loop through history records to get previous owner which is a group
        for (LiveChatTranscriptHistory histVar : transHistoryList) {
            if (histVar.OldValue != null && histVar.OldValue instanceof Id
                && CDdUtilities.idIsGroup(histVar.OldValue)
                && !lctToQueueIdMap.containsKey(histVar.LiveChatTranscriptId)) { 
                ownerIds.add((Id)histVar.OldValue);
                lctToQueueIdMap.put(histVar.LiveChatTranscriptId, (Id)histVar.OldValue);
            }
        }
        CDdGenericTriggerOptimizationHelper.setQueueMap(ownerIds); //set queue map in memory
        Map<Id,Group> queueMap = CDdGenericTriggerOptimizationHelper.getQueueMap(); //load from memory
        if (queueMap.isEmpty()) {
            return;
        }
        for (LiveChatTranscript lctVar : newList) {
            if (lctToQueueIdMap.containsKey(lctVar.Id) && lctVar.CaseId != null 
                && relatedCasesMap.containsKey(lctVar.CaseId)) {
                    lctToProcess.add(lctVar);
            }
        }
        for (LiveChatTranscript lctVar : lctToProcess) {
            Case caseObj = relatedCasesMap.get(lctVar.CaseId);
            if (caseObj != null && caseObj.Initial_Queue__c != String.valueOf(lctToQueueIdMap.get(lctVar.Id))
                && lctToQueueIdMap.get(lctVar.Id).getSObjectType()==Group.sObjectType) {
                Map<String,Object> fieldVal = new Map<String,Object>{
                    'Initial_Queue__c' => String.valueOf(lctToQueueIdMap.get(lctVar.Id)),
                    'Initial_Queue_Name__c' => queueMap.get(lctToQueueIdMap.get(lctVar.Id)).Name
                };
                CDdLiveChatTransOptimizationHelper.setSobjectToUpdate(CDdSupportConstants.CASE_OBJECT_LABEL,lctVar.CaseId,fieldVal);
            }
        }
    }

    /** 
    * @author     Sahil Chaudhry
    * @date       12/2021
    * @decription BIZS-814 sets name on related case record (optimized)
    * @param      trigger.newList and oldMap   
    * @return     None
    */
    public static void populateCaseSuppliedName(List<LiveChatTranscript> newList, Map<Id,LiveChatTranscript> oldMap) {
        Map<Id,Case> relatedCasesMap = CDdLiveChatTransOptimizationHelper.getCaseMap();//get from memory
        for (LiveChatTranscript trans : newList) {
            if (trans.CaseId != null && relatedCasesMap.containsKey(trans.CaseId)
                && String.isNotBlank(trans.Chat_First_Name__c) && String.isNotBlank(trans.Chat_Last_Name__c)) {
                    String concatName = trans.Chat_First_Name__c + CDdCoreConstants.DELIMITER_SPACE + trans.Chat_Last_Name__c;
                if (relatedCasesMap.get(trans.CaseId).SuppliedName != concatName
                    || relatedCasesMap.get(trans.CaseId).Full_Name__c != concatName) {
                    Map<String,Object> fieldVal = new Map<String,Object>{
                        'SuppliedName' => concatName,
                        'Full_Name__c' => concatName
                    };
                    CDdLiveChatTransOptimizationHelper.setSobjectToUpdate(CDdSupportConstants.CASE_OBJECT_LABEL,trans.CaseId,fieldVal);
                }
            }
        }
    }

    /** 
    * @author     Sahil Chaudhry
    * @date       12/2021
    * @decription BIZS-814 link transcripts with cases based on transcript ChatKey (optimized)
    * @param      trigger.newList and oldMap   
    * @return     None
    */
    public static void populateCaseWithChatKey(List<LiveChatTranscript> newList, Map<Id,LiveChatTranscript> oldMap) {
        List<LiveChatTranscript> lctToProcess = new List<LiveChatTranscript>();
        //get cases based on lct chat keys and populate transcripts with case ids
        Set<String> lctChatKeys = new Set<String>();
        for (LiveChatTranscript lctVar : newList) {
            if (String.isNotBlank(lctVar.ChatKey) && lctVar.CaseId == null
                && isNewOrFieldUpdated(lctVar, oldMap, 'ChatKey')) {
                lctChatKeys.add(lctVar.ChatKey);
                lctToProcess.add(lctVar);
            }
        }
        List<Case> casesFromDB = Database.query(CDdLiveChatTransOptimizationHelper.getCaseBaseQuery() +
                                                 ' WHERE ChatKey__c IN :lctChatKeys ORDER BY CreatedDate DESC');
        CDdLiveChatTransOptimizationHelper.addToCaseMap(casesFromDB);
        Map<String,Id> chatKeyToCaseMap = new Map<String,Id>();
        for (Case caseVar : casesFromDB) {
            if (!chatKeyToCaseMap.containsKey(caseVar.ChatKey__c)) {
                chatKeyToCaseMap.put(caseVar.ChatKey__c, caseVar.Id);
            } 
        }
        for (LiveChatTranscript lctVar : lctToProcess) {
            if (chatKeyToCaseMap.containsKey(lctVar.ChatKey)) {
                lctVar.CaseId = chatKeyToCaseMap.get(lctVar.ChatKey);
            }
        }
    }

    public class CDdLiveChatTransTriggerHelperException extends Exception {}
}