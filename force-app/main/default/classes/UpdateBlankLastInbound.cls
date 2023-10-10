/********************************************************************************************************************
* @author Jose Vega (Perficient, Inc.)
* @date 06/02/2021
*
* @description Fill in all blank Last Inbound Date/Time field on Lead Object with most current campaign response date/time.
*
**************************************************************************************************************************************/
public class UpdateBlankLastInbound implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
  
    public Integer recordsProcessed = 0;
  
    // Gets all Leads that need updating
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator('SELECT Id, Name, Last_Inbound_Date_Time__c, Created_Date_Time__c, Primary_Campaign_Source__c' +
            ' FROM Lead WHERE (Last_Inbound_Date_Time__c = null AND Primary_Campaign_Source__c != null AND isConverted = FALSE )' +
            ' AND (Primary_Campaign_Source_Name__c LIKE \'%AcqMktg%\') LIMIT 20000');
    }

    public void execute(Database.BatchableContext bc, List<Lead> records){
        Set<String> leadTocampId = new Set<String>();
        for(Lead lead : records){
            String campaignId = Id.valueOf(Lead.Primary_Campaign_Source__c);
            String leadId = Id.valueOf(Lead.Id);
            leadTocampId.add(campaignId.left(15) + '|' + leadId.left(15));
        }

        List<Lead> leadsToUpdateLastInbound = new List<Lead>();

        Map<Id, CampaignMember> camMembers = new Map<Id,CampaignMember>([
            SELECT Id, CreatedDate, LeadId
            FROM CampaignMember
            WHERE
                CampaignId_LeadId__c IN :leadTocampId]);

        Map<Id, Id> leadTocamMembers = new Map<Id, Id>();
        for(CampaignMember cm : camMembers.values()){
            leadTocamMembers.put(cm.LeadId, cm.Id);
        }

        for(Lead currentLead : records){
            Id leadId = currentLead.Id;
            Id campaignMemberId = leadTocamMembers.get(leadId);

            if (camMembers.containsKey(campaignMemberId) && 
                currentLead.Last_Inbound_Date_Time__c == null &&
                currentLead.Primary_Campaign_Source__c != null) {
                
                    CampaignMember cmember = camMembers.get(campaignMemberId);
                    currentLead.Last_Inbound_Date_Time__c = cmember.CreatedDate;
                    leadsToUpdateLastInbound.add(currentLead);
                    recordsProcessed++;
            }
        }
        List<Database.SaveResult> sResults = Database.update(leadsToUpdateLastInbound, false);
    }

    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
        System.debug(recordsProcessed + ' Records Processed.');
    }

    public void execute(SchedulableContext sc) {
        Integer batchSize = (Label.UpdateBlankLastInbound_BatchSize <> null && Label.UpdateBlankLastInbound_BatchSize.isNumeric() ? Integer.valueof(Label.UpdateBlankLastInbound_BatchSize) : 50 ) ; 
        UpdateBlankLastInbound updateBlankInboundSch = new UpdateBlankLastInbound();
        database.executebatch(updateBlankInboundSch, batchSize);
    }
}