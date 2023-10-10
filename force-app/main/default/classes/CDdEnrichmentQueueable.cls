public class CDdEnrichmentQueueable implements Queueable,Database.AllowsCallouts{

    Map<id,String> accIDChdIdMap;
    Enrichment_Account__c enrAccRec;
    Enrichment_Junction__c enrcJunRec;
    List<Enrichment_Account__c> enrAccList;
    List<Enrichment_Junction__c> enrJunList;

    Set<String> chdIdSet = new Set<String>();
    Map<id, Account> newMap = new Map<Id, Account>();
    Map<Id, Account> oldMap = new Map<id,Account>();

    //Constructor of CDdEnrichmentQueueHandler
    public CDdEnrichmentQueueable(Map<id, Account> newMap, Map<Id, Account> oldMap){
        this.newMap = newMap;
        this.oldMap = oldMap;
        this.chdIdSet = getChdIdSet();
    }

    public void execute(QueueableContext context) {
        try{
            List<Enrichment_Account__c> finalEnrichmentAccountList = new list<Enrichment_Account__c>();
            List<Enrichment_Junction__c> finalEnrichmentJunctionList = new List<Enrichment_Junction__c>();

            finalEnrichmentJunctionList = handleEnrichmentJunctionUpsert();
            if(!finalEnrichmentJunctionList.isEmpty()){
                upsert finalEnrichmentJunctionList;
            }
            if(!finalEnrichmentJunctionList.isEmpty()){
                finalEnrichmentAccountList = handleEnrichmentAccountUpsert(finalEnrichmentJunctionList);
            }
            if(!finalEnrichmentAccountList.isEmpty()){
                upsert finalEnrichmentAccountList;
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Enrichment Account / Enrichment Junction CHD ID ' + ex.getMessage()}, 'CDdAccountHelperMethods',
                                             'handleEnrichmentAccountJuctionCHDID', LoggingLevel.ERROR);
            throw ex;
        }
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-15255: This method get Set of ChdId from Account
    * return Set<String> return Set of CHD_ID__c
    */
    public Set<String> getChdIdSet(){
        Set<String> accChdIdSet = new Set<String>();
        for(Account currAcc : newMap.values()){
            accChdIdSet.add(currAcc.CHD_ID__c);
            if(oldMap != null && String.isNotBlank(oldMap.get(currAcc.id).CHD_ID__c)){
                accChdIdSet.add(oldMap.get(currAcc.id).CHD_ID__c);
            }
        }
        return accChdIdSet;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-15255: This method get final List the Enrichment Junction Record
    * return List<Enrichment_Junction__c> return final list of Enrichment Junction which need to be upserted
    */
    public List<Enrichment_Junction__c> handleEnrichmentJunctionUpsert(){

        List<Enrichment_Junction__c> finalEnrichJunList = new List<Enrichment_Junction__c>();
        Map< Map<id,String>, Enrichment_Junction__c> enrichJunAccMap = new Map<Map<id,String> , Enrichment_Junction__c>();
        Map< String , List<Enrichment_Junction__c>> enrichJunBlankAccMap = new Map< String , List<Enrichment_Junction__c>>();

        List<Enrichment_Junction__c> enrichJunList = [SELECT Id, EJ_CHD_ID__c,Account__c FROM Enrichment_Junction__c
                                                      WHERE EJ_CHD_ID__c =: chdIdSet AND (Account__c =: newMap.keySet() OR Account__c = null) Limit 10000];

        //In this loop we are seprating Enrichment Junction Record where Account = null & where Account != null in different map
        for(Enrichment_Junction__c currEnrichJun : enrichJunList){
            if(String.isNotBlank(currEnrichJun.Account__c)){
                accIDChdIdMap = new Map<id,String>();
                accIDChdIdMap.put(currEnrichJun.Account__c,currEnrichJun.EJ_CHD_ID__c);
                enrichJunAccMap.put( accIDChdIdMap, currEnrichJun);
            }
            else {
                enrJunList = new List<Enrichment_Junction__c>();
                if(enrichJunBlankAccMap.containsKey(currEnrichJun.EJ_CHD_ID__c)){
                    enrJunList = enrichJunBlankAccMap.get(currEnrichJun.EJ_CHD_ID__c);
                }
                enrJunList.add(currEnrichJun);
                enrichJunBlankAccMap.put(currEnrichJun.EJ_CHD_ID__c, enrJunList);
            }
        }
        finalEnrichJunList = filterEnrichJuncRecordsForInsert(enrichJunAccMap,enrichJunBlankAccMap);

        return finalEnrichJunList;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-15255: This method get final List the Enrichment Account Record
    * @param List<Enrichment_junction__c> Enrichment Junction Record which will be connected to Enrichment Account
    * return List<Enrichment_Account__c> return final list of Enrichment Account which need to be upserted
    */
    public List<Enrichment_Account__c> handleEnrichmentAccountUpsert(List<Enrichment_Junction__c> enrichmentJunctionList){

        List<Enrichment_Account__c> finalEnrichAccList = new List<Enrichment_Account__c>();
        Map< Map<id,String>, Enrichment_Account__c> enrichAccMap = new Map<Map<id,String> , Enrichment_Account__c>();
        Map< Map<id,String>, Enrichment_Junction__c> enrichJunAccMap = new Map<Map<id,String> , Enrichment_Junction__c>();
        Map< String , List<Enrichment_Account__c>> enrichBlankAccMap = new Map< String , List<Enrichment_Account__c>>();

        List<Enrichment_Account__c> enrichAccList = [SELECT Id, CHD_ID__c,Account__c, Enrichment_Junction__c  FROM Enrichment_Account__c
                                                     WHERE CHD_ID__c =: chdIdSet AND (Account__c =: newMap.keySet() OR Account__c = null) Limit 10000];

        //In this loop we are seprating Enrichment Account Record where Account = null & where Account != null in different map
        for(Enrichment_Account__c currEnrAcc : enrichAccList){
            if(String.isNotBlank(currEnrAcc.Account__c)){
                accIdChdIdMap = new Map<id,String>();
                accIdChdIdMap.put(currEnrAcc.Account__c,currEnrAcc.CHD_ID__c);
                enrichAccMap.put(accIdChdIdMap, currEnrAcc);
            }else {
                enrAccList = new List<Enrichment_Account__c>();
                if(enrichBlankAccMap.containsKey(currEnrAcc.CHD_ID__c)){
                    enrAccList = enrichBlankAccMap.get(currEnrAcc.CHD_ID__c);
                }
                enrAccList.add(currEnrAcc);
                enrichBlankAccMap.put(currEnrAcc.CHD_ID__c, enrAccList);
            }
        }

        //In this loop to get Enrichment Junction Record with Account ID & CHD ID as a key
        for(Enrichment_Junction__c currEnrJun : enrichmentJunctionList){
            if(String.isNotBlank(currEnrJun.Account__c)){
                accIdChdIdMap = new Map<id,String>();
                accIdChdIdMap.put(currEnrJun.Account__c,currEnrJun.EJ_CHD_ID__c);
                enrichJunAccMap.put(accIdChdIdMap, currEnrJun);
            }
        }

        finalEnrichAccList = filterEnrichAccRecordsForInsert(enrichAccMap,enrichBlankAccMap,enrichJunAccMap);

        return finalEnrichAccList;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-15255: This method get List the Enrichment Junction Record with correct CHD_ID & AccountID
    * @param Map<Map<id,String>,Enrichment_Junction__c> Enrichment Junction Record with Correct CHD_ID & Account ID as key
    * @param Map<String,List<Enrichment_Junction__c>> Enrichment Junction Record List where AccountID is blank having CHD ID as key
    * return List<Enrichment_Junction__c> return list of Enrichment Junction after filter
    */
    public List<Enrichment_Junction__c> filterEnrichJuncRecordsForInsert(Map<Map<id,String>,Enrichment_Junction__c> enrichJunAccMap, Map<String,List<Enrichment_Junction__c>> enrichJunBlankAccMap){
        List<Enrichment_Junction__c> finalEnrichJunList = new List<Enrichment_Junction__c>();

        /* This loop is to check if any Enrichment Junction Record exist for that Account ID & CHD ID if yes the use that record
        otherwise check if there any Enrichment Junction Record exist where Account ID as null & CHD ID as account CHD ID then use that record
        otherwise create a new Enrichment Junction Record & Remove the reference of Account ID from old Enrichment Junction Record.
        */
        for(Account currAccRec : newMap.values()){
            if(String.isNotBlank(currAccRec.CHD_ID__c)){
                accIDChdIdMap = new Map<id,String>();
                accIDChdIdMap.put(currAccRec.id,currAccRec.CHD_ID__c);

                if(enrichJunAccMap.containsKey(accIDChdIdMap)){
                    finalEnrichJunList.add(enrichJunAccMap.get(accIDChdIdMap));
                }else if(!enrichJunAccMap.containsKey(accIDChdIdMap) && enrichJunBlankAccMap.containsKey(currAccRec.CHD_ID__c)){
                    enrJunList = enrichJunBlankAccMap.get(currAccRec.CHD_ID__c);

                    enrJunList[0].Account__c = currAccRec.id;
                    finalEnrichJunList.add(enrJunList[0]);

                    enrJunList.remove(0);
                    if(enrJunList.size() > 0){
                        enrichJunBlankAccMap.put(currAccRec.CHD_ID__c, enrJunList);
                    }else{
                        enrichJunBlankAccMap.remove(currAccRec.CHD_ID__c);
                    }
                }else {
                    enrcJunRec = new Enrichment_Junction__c();
                    enrcJunRec.Account__c = currAccRec.id;
                    enrcJunRec.EJ_CHD_ID__c = currAccRec.CHD_ID__c;
                    finalEnrichJunList.add(enrcJunRec);
                }
            }
            if(oldMap != null && oldMap.containsKey(currAccRec.id) && String.isNotBlank(oldMap.get(currAccRec.id).CHD_ID__c)){
                accIDChdIdMap = new Map<id,String>();
                accIDChdIdMap.put(oldMap.get(currAccRec.id).id,oldMap.get(currAccRec.id).CHD_ID__c);

                if(enrichJunAccMap.containsKey(accIDChdIdMap)){
                    enrcJunRec = new Enrichment_Junction__c();
                    enrcJunRec = enrichJunAccMap.get(accIDChdIdMap);
                    enrcJunRec.Account__c = null;
                    finalEnrichJunList.add(enrcJunRec);
                }
            }
        }
        return finalEnrichJunList;
    }

    /**
    * @author Sanidhya Jain
    * @description BASD-15255: This method get List the Enrichment Account Record with correct CHD_ID & AccountID
    * @param Map<Map<id,String>,Enrichment_Account__c> Enrichment Account Record with Correct CHD_ID & Account ID as key
    * @param Map<String,List<Enrichment_Account__c>> Enrichment Account Record List where AccountID is blank having CHD ID as key
    * @param Map<Map<id,String>,Enrichment_Junction__c> Enrichment Junction Record with Correct CHD_ID & Account ID as key
    * return List<Enrichment_Account__c> return list of Enrichment Account after filter
    */
	public List<Enrichment_Account__c> filterEnrichAccRecordsForInsert(Map<Map<id,String>,Enrichment_Account__c> enrichAccMap, Map<String,List<Enrichment_Account__c>> enrichBlankAccMap, Map<Map<id,String>,Enrichment_Junction__c> enrichJunAccMap){
        List<Enrichment_Account__c> finalEnrichAccList = new List<Enrichment_Account__c>();

        /* This loop is to check if any Enrichment Account Record exist for that Account ID & CHD ID if yes the use that record
        otherwise check if there any Enrichment Account Record exist where Account ID as null & CHD ID as account CHD ID then use that record
        otherwise create a new Enrichment Account Record & Remove the reference of Account ID from old Enrichment Account Record.
        */
        for(Account currAccRec : newMap.values()){
            if(String.isNotBlank(currAccRec.CHD_ID__c)){
                accIdChdIdMap = new Map<id,String>();
                accIdChdIdMap.put(currAccRec.id,currAccRec.CHD_ID__c);

                if(enrichAccMap.containsKey(accIdChdIdMap)){
                    enrAccRec = new Enrichment_Account__c();
                    enrAccRec = enrichAccMap.get(accIdChdIdMap);
                    enrAccRec.Enrichment_Junction__c = enrichJunAccMap.get(accIdChdIdMap).id;
                    finalEnrichAccList.add(enrAccRec);
                }else if(!enrichAccMap.containsKey(accIdChdIdMap) && enrichBlankAccMap.containsKey(currAccRec.CHD_ID__c)){
                    enrAccList = enrichBlankAccMap.get(currAccRec.CHD_ID__c);

                    enrAccList[0].Account__c = currAccRec.id;
                    enrAccList[0].Enrichment_Junction__c = enrichJunAccMap.get(accIdChdIdMap).id;
                    finalEnrichAccList.add(enrAccList[0]);

                    enrAccList.remove(0);
                    if(enrAccList.size() > 0){
                        enrichBlankAccMap.put(currAccRec.CHD_ID__c, enrAccList);
                    }else{
                        enrichBlankAccMap.remove(currAccRec.CHD_ID__c);
                    }
                }
                else {
                    enrAccRec = new Enrichment_Account__c();
                    enrAccRec.Account__c = currAccRec.id;
                    enrAccRec.CHD_ID__c = currAccRec.CHD_ID__c;
                    enrAccRec.Enrichment_Junction__c = enrichJunAccMap.get(accIdChdIdMap).id;
                    finalEnrichAccList.add(enrAccRec);
                }
            }
            if(oldMap != null && oldMap.containsKey(currAccRec.id) && String.isNotBlank(oldMap.get(currAccRec.id).CHD_ID__c)){
                accIdChdIdMap = new Map<id,String>();
                accIdChdIdMap.put(oldMap.get(currAccRec.id).id,oldMap.get(currAccRec.id).CHD_ID__c);

                if(enrichAccMap.containsKey(accIdChdIdMap)){
                    enrAccRec = new Enrichment_Account__c();
                    enrAccRec = enrichAccMap.get(accIdChdIdMap);
                    enrAccRec.Account__c = null;
                    finalEnrichAccList.add(enrAccRec);
                }
            }
        }
        return finalEnrichAccList;
    }
}