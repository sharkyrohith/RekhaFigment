/** 
 * @author: Ila Mahehswari
 * @date : 2022-03
 * @description: Factory to create Camapign and Campaign Member
 */

public class TDdCampaignCampaignMemberFactory {
    
    //Create Campaigns
    public static List<Campaign> createCampaigns(String Name, Integer numberOfCampaigns, String RecordTypeId, boolean doInsert) {
        
        List<Campaign> campaignToBeCreated = new List <Campaign>(); 
        for (Integer count = 0 ; count < numberOfCampaigns; count++) {
            Campaign currCampaign = new Campaign (Name = Name + count,
                                                  Title__c = Name + count,          
                                                  RecordTypeId = RecordTypeId); 
            
            campaignToBeCreated.add(currCampaign);
        }
        if(doInsert) {
            insert campaignToBeCreated; 
        }
        return campaignToBeCreated; 
    }
    
    //Create Campaign Member with Campaign
    public static CampaignMember createCampaignMember(String CampaignId, String ContactId, String LeadId, boolean doInsert) {
        
        CampaignMember currCampaign = new CampaignMember (CampaignId = CampaignId,
                                                  ContactId = ContactId != null ? ContactId : null,
                                                  LeadId = LeadId != null ? LeadId : null); 
        if(doInsert) {
            insert currCampaign; 
        }
        return currCampaign; 
    }
}