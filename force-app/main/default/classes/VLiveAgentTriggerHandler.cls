/**
 * RA, 03/07/2017
 * Handler should connect the chat transcript to case and the fields
 * back to the case for wait time and duration.
 */
public class VLiveAgentTriggerHandler implements TriggerInterface { 
  
  // list of affected transcript events
  Map<Id, LiveChatTranscript> chatTranscript;
  Map<Id,LiveChatTranscript> oldChatTranscript;

  // just initialize the collectoin
  public VLiveAgentTriggerHandler() {
    System.debug('>>>Details: ' + Trigger.new);
    if(Trigger.isInsert || Trigger.isUpdate) {
      chatTranscript = (Map<Id, LiveChatTranscript>)Trigger.newmap;
      oldChatTranscript = (Map<Id,LiveChatTranscript>)Trigger.oldMap;
    }
  }
  
  public void bulkAfter(){
    if(!Trigger.isInsert && !Trigger.isUpdate) return;
    
    Set<String> chatKeys = new Set<String>();
    
    // for update event the case id is present
    Set<Id> scriptCaseIds = new Set<Id>();

    Set<Id> scriptOldCaseIds = new Set<Id>();
    Map<String, LiveChatTranscript> mapCKeyToTS = new Map<String, LiveChatTranscript>();

    for ( LiveChatTranscript transcript : chatTranscript.values() ){
      if(transcript.Status=='Completed'){
        if ( transcript.caseId==null && transcript.chatKey!=null ) {
          chatKeys.add( transcript.chatKey );
          mapCKeyToTS.put(transcript.chatKey, transcript);
        }
        else {
          if(transcript.caseId != null) {
            scriptCaseIds.add(transcript.caseId);
          }
        }
          
      }
    }

    List<Case> caseUpdateList = new List<Case>();
    
    if(oldChatTranscript != null) {
      for ( LiveChatTranscript transcript : oldChatTranscript.values() ){
        if(transcript.caseId != null && transcript.caseId != chatTranscript.get(transcript.id).caseId) {
          scriptOldCaseIds.add(transcript.caseId);
        }
      }
      Map<Id, Case> mapOldCases = new Map<Id, Case>([SELECT id, ChatWaitTime__c,ChatDuration__c 
        FROM Case WHERE id in :scriptOldCaseIds]);

      if(mapOldCases.size() > 0) {
        for(LiveChatTranscript oldTs: oldChatTranscript.values()) {
          if(oldTs.caseId != null) {
            integer waitTime, duration;
            LiveChatTranscript ts = chatTranscript.get(oldTs.id);
            if(ts != null) {
              waitTime = ts.WaitTime;
              duration = ts.ChatDuration;

              Case cObj = mapOldCases.get(oldTs.CaseId);
              if(cObj != null && cObj.ChatDuration__c != null && Duration != null) {
                cObj.ChatDuration__c -= Duration;
              }
              if(cObj != null && cObj.ChatWaitTime__c != null && WaitTime != null) {
                cObj.ChatWaitTime__c -= WaitTime;
              }
              caseUpdateList.add(cObj);
            }
          }
        }
      }
    }

    System.debug('>>>keys: ' + chatKeys);
      
    if ( chatKeys.size() > 0 || scriptCaseIds.size() > 0) {
      Date yesterday = Date.today().addDays(-1);
      List<Case> cases = new List<Case>([SELECT id, ChatKey__c,ChatWaitTime__c,ChatDuration__c 
        FROM Case WHERE (ChatKey__c IN :chatKeys or id in :scriptCaseIds)
        and createddate >= :yesterday]);
      Map<String, Case> chatKeyCasesMap = new Map<String, Case>();
      
      /**
       * in addition get aggregate of all live agent transcripts related to cases
       */
      Map<Id, AggregateResult> mapCaseToAggregate = new Map<Id, AggregateResult>();
      for(AggregateResult result: [Select CaseId, sum(WaitTime) WaitTime, sum(ChatDuration) Duration
        from LiveChatTranscript where caseId in :cases
        group by CaseId]) {
        mapCaseToAggregate.put((Id)result.get('CaseId'), result);
      }

      for( Case cs : cases ) {
        AggregateResult result = mapCaseToAggregate.get(cs.id);
        if(result != null) {
          cs.ChatWaitTime__c = (Decimal)(result.get('WaitTime'));
          cs.ChatDuration__c = (Decimal)(result.get('Duration'));
        }
        integer waitTime, duration;
        LiveChatTranscript ts = mapCKeyToTS.get(cs.ChatKey__c);
        if(ts != null) {
          waitTime = ts.WaitTime;
          duration = ts.ChatDuration;
        }
        if(Trigger.isInsert) {
          if(cs.ChatWaitTime__c != null) {
            cs.ChatWaitTime__c += WaitTime;
          }
          else {
            cs.ChatWaitTime__c = WaitTime;
            
          }
          if(cs.ChatDuration__c != null) {
            cs.ChatDuration__c += Duration;
          }
          else {
            cs.ChatDuration__c = Duration;
            
          }
        }
        cs.Chat_Type__c = 'Served Chat';
        caseUpdateList.add(cs);
        chatKeyCasesMap.put( cs.ChatKey__c, cs );
      }
      
      if(caseUpdateList.size() > 0){
        update caseUpdateList;
      }
      
      List<LiveChatTranscript> transcriptsToUpdate = new List<LiveChatTranscript>();
      
      for ( LiveChatTranscript transcript : chatTranscript.values()) {
        System.debug('@@@@@@@'+transcript);
        if (transcript.caseId==null&&transcript.chatKey!=null ) {
          Case cs = chatKeyCasesMap.get( transcript.chatKey );
          if ( cs != null ) {
            transcriptsToUpdate.add(new LiveChatTranscript(
              id = transcript.id,
              caseId = cs.id));
          }

        }
      }

      if(transcriptsToUpdate.size()>0){
        System.debug( 'transcriptsToUpdate: ' + transcriptsToUpdate );
        update transcriptsToUpdate;
      }
    }
  }
  
  public void bulkBefore(){}
  public void beforeInsert(SObject so){}
  public void beforeUpdate(SObject oldSo, SObject so){}
  public void beforeDelete(SObject so){}
  public void afterInsert(SObject so){}
  public void afterUpdate(SObject oldSo, SObject so){}
  public void afterDelete(SObject so){}
  public void afterUndelete(SObject so){} 
  public void andFinally() {}    

}