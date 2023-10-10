public class CDdACContactTraceTriggerHandler {
    public void beforeInsert(List<amazonconnect__AC_ContactTraceRecord__c> newList) {
        fillCaseOppOnIO(newList);
    }

    public void afterInsert(List<amazonconnect__AC_ContactTraceRecord__c> newList) {
        updateCaseToAbandonned(newList);
        fillWithAOC(newList);
    }

    /**
    * @author Tia Xuan
    * @date 2020-10
    * 
    * @description BZAPSUP-1091 Trigger on AC Contact Trace Record
    *                           Update case to abandonned on AOC abandonned calls
    */
    private static void updateCaseToAbandonned(List<amazonconnect__AC_ContactTraceRecord__c> newList){
        List<Case> casesToUpdate = new List<Case>();
        for (amazonconnect__AC_ContactTraceRecord__c rec : newList){
            if (rec.amazonconnect__QueueEnqueueTimestamp__c != null
                && rec.amazonconnect__Initiation_Method__c.equalsIgnoreCase('INBOUND')
                && rec.amazonconnect__NextContactId__c == null
                && rec.Case__c != null
                && rec.amazonconnect__AgentConnectedToAgentTimestamp__c == null){
                Case c = new Case();
                c.Id = rec.Case__c;
                c.Status = 'Abandoned';
                
                // BZAPSUP-1140 Case Assignment Rules triggering on phone cases. 
                // Disable case re-assignments
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = false;
                c.setOptions(dmo);
                
                casesToUpdate.add(c);
            }
        }

        if (casesToUpdate.size() > 0){
            update casesToUpdate;
        }

    }

    /**
    * @author Tia Xuan
    * @date 2020-10
    * 
    * @description BZAPSUP-1099 Trigger on Case Record for Outbound CTRs
    *                           Update case on outbound call with no case / opportunity
    *                           as well as inbound calls with no case / opportunity
    */
    private static void fillCaseOppOnIO(List<amazonconnect__AC_ContactTraceRecord__c> newList){
        DateTime pastHour = DateTime.now().addMinutes(-60);
        List<amazonconnect__AC_ContactTraceRecord__c> affectedCTRList = new List<amazonconnect__AC_ContactTraceRecord__c>();
        Set<String> agentNames = new Set<String>();
        for (amazonconnect__AC_ContactTraceRecord__c rec : newList) {
            if  (  (rec.Case__c == null && rec.Opportunity__c == null)
                && (rec.amazonconnect__Initiation_Method__c == 'OUTBOUND' ||
                    rec.amazonConnect__Initiation_Method__c == 'INBOUND')
                && String.isNotBlank(rec.amazonconnect__AgentUsername__c)
            ) {
                affectedCTRList.add(rec);
                agentNames.add(rec.amazonconnect__AgentUsername__c);
            }
        }

        // NOTE: These records are used for both INBOUND and OUTBOUND calls on both Case and Opportunity now ...
        List<AC_Outbound_Call__c> outboundList = [
            SELECT Id, Agent_Username__c, Case__c, Opportunity__c, AC_Contact_Trace_Record__c, CreatedDate
            FROM AC_Outbound_Call__c
            WHERE CreatedDate >= :pastHour
            AND Agent_Username__c IN :agentNames
            AND AC_Contact_Trace_Record__c = null
            ORDER BY CreatedDate ASC
        ];
        
        Map<String, List<AC_Outbound_Call__c>> outboundMap = new Map<String, List<AC_Outbound_Call__c>>();
        for (AC_Outbound_Call__c call : outboundList) {
            if (!outboundMap.containsKey(call.Agent_Username__c))
                outboundMap.put(call.Agent_Username__c, new List<AC_Outbound_Call__c>());
            List<AC_Outbound_Call__c> currentList = outboundMap.get(call.Agent_Username__c);
            currentList.add(call);
            outboundMap.put(call.Agent_Username__c, currentList);
        }

        for (amazonconnect__AC_ContactTraceRecord__c rec : affectedCTRList){
            if (outboundMap.containsKey(rec.amazonconnect__AgentUsername__c)){
                List<AC_Outbound_Call__c> lst = outboundMap.get(rec.amazonconnect__AgentUsername__c);
                for (AC_Outbound_Call__c call : lst) {
                    // skip the GetElapsedTimeInSeconds calculation if amazonconnect__AfterContactWorkStartTimestamp__c is null
                    if (rec.amazonconnect__AfterContactWorkStartTimestamp__c != null) {
                        Long timeLapsed = GetElapsedTimeInSeconds(rec.amazonconnect__AfterContactWorkStartTimestamp__c, call.CreatedDate);
                        if (timeLapsed > 0 && timeLapsed < 90) {
                            rec.Case__c = call.Case__c;
                            rec.Opportunity__c = call.Opportunity__c;
                        }
                    }
                }
            }
        }
    }

    /**
    * @author Tia Xuan
    * @date 2020-10
    * 
    * @description BZAPSUP-1099 Trigger on Case / Opportunity Record for Inbound and Outbound CTRs
    *                           Updates the outbound relationship AOC record with the corresponding AOC.
    *                           as well as the inbound relationship AOC record with the corresponding AOC.
    */
    private static void fillWithAOC(List<amazonconnect__AC_ContactTraceRecord__c> newList){
        Set<String> agentNames = new Set<String>();
        Map<Id, amazonconnect__AC_ContactTraceRecord__c> caseMap = new Map<Id, amazonconnect__AC_ContactTraceRecord__c>();
        Map<Id, amazonconnect__AC_ContactTraceRecord__c> oppMap = new Map<Id, amazonconnect__AC_ContactTraceRecord__c>();
        for (amazonconnect__AC_ContactTraceRecord__c rec : newList){
            if  (rec.Case__c != null 
                && (rec.amazonconnect__Initiation_Method__c == 'OUTBOUND' ||
                    rec.amazonconnect__Initiation_Method__c == 'INBOUND')
                && String.isNotBlank(rec.amazonconnect__AgentUsername__c)
            ) {
                agentNames.add(rec.amazonconnect__AgentUsername__c);
                caseMap.put(rec.Case__c, rec);
            }
            else if  (rec.Opportunity__c != null 
                && (rec.amazonconnect__Initiation_Method__c == 'OUTBOUND' ||
                    rec.amazonconnect__Initiation_Method__c == 'INBOUND')
                && String.isNotBlank(rec.amazonconnect__AgentUsername__c)
            ) {
                agentNames.add(rec.amazonconnect__AgentUsername__c);
                oppMap.put(rec.Opportunity__c, rec);
            }
        }  

        // NOTE: These records are used for both INBOUND and OUTBOUND calls on both Case and Opportunity now ...
        List<AC_Outbound_Call__c> outboundList = [
            SELECT Id, Agent_Username__c, Case__c, Opportunity__c, AC_Contact_Trace_Record__c
            FROM AC_Outbound_Call__c
            WHERE (Case__c IN :caseMap.keySet() OR Opportunity__c IN :oppMap.keySet())
            AND Agent_Username__c IN :agentNames
            AND AC_Contact_Trace_Record__c = null
        ];
        
        List<AC_Outbound_Call__c> outboundUpdateList = new List<AC_Outbound_Call__c>();
        for (AC_Outbound_Call__c aoc : outboundList) {
            if ((aoc.Case__c != null) && (caseMap.containsKey(aoc.Case__c))) {
                aoc.AC_Contact_Trace_Record__c = caseMap.get(aoc.Case__c).Id;
                outboundUpdateList.add(aoc);
            }
            else if ((aoc.Opportunity__c != null) && (oppMap.containsKey(aoc.Opportunity__c))) {
                aoc.AC_Contact_Trace_Record__c = oppMap.get(aoc.Opportunity__c).Id;
                outboundUpdateList.add(aoc);
            }
        }
        
        if (outboundUpdateList.size() > 0){
            update outboundUpdateList;
        }
    }

     /**
    * @author Tia Xuan
    * @date 2020-10
    * 
    * @description BZAPSUP-1099 Trigger on Case Record for Outbound CTRs
    *                           helper method to get elapsed time in seconds
    */
    private static Long GetElapsedTimeInSeconds(DateTime startDT, DateTime endDT){
        Long dt1Long = startDT.getTime();
        Long dt2Long = endDT.getTime();
        Long milliseconds = dt2Long - dt1Long;
        Long seconds = milliseconds / 1000;
        return seconds;
    }
}