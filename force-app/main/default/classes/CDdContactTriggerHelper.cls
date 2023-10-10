/* 
* @Author Lathika
* @Date January 2022
* @description 
*/
public class CDdContactTriggerHelper {
    /**
   * @author Lathika
   * @date 2022-01
   * @description BZAP - 13013 
   * @param String 
   * @return Boolean Value of the checkbox
   */
  public static Boolean getContactFeatureFlag(String flagName){
    Contact_Feature_Flag__c conFeatureSetting = Contact_Feature_Flag__c.getInstance();
        if (conFeatureSetting != null){
            return (Boolean) conFeatureSetting.get(flagName) != null ? (Boolean) conFeatureSetting.get(flagName) : false;
        } else {
            return false;
        }
    }

    /**
   * @author Lathika
   * @date 2022-01
   * @description BZAP - 13013 insert campaign while running test
   * @param null
   * @return null
   */
  public static void insertCampaign(){
    try{
        List<Campaign> campaignList = [Select id,
                                              Name
                                      from Campaign
                                      where name = :System.label.CampaignNameMxAcqMktg];
        if(campaignList.size()== 0){
            Campaign campaignToInsert = new Campaign();
            campaignToInsert.Name = System.label.CampaignNameMxAcqMktg;
            campaignToInsert.Title__c = 'Unmanaged Caviar to DD X-Sell';
            insert campaignToInsert;           
        } 
    } catch(Exception e){
        CDdErrorUtilities.publishException('Contact','insert campaign member', e);
    }
  }

}