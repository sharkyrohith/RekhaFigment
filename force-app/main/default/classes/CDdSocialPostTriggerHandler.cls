/**
 *
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Social Post trigger handler migration from old VSocialPost
 *
 */
public class CDdSocialPostTriggerHandler {
    public void beforeInsert (List<SocialPost> newList) {
        //CDdSocialPostTriggerHelper.updateSocialInfluencer(newList);
        CDdSocialPostTriggerHelper.updateSocialCases(newList);
    }
    public void beforeUpdate(List<SocialPost> newList, Map<Id, SocialPost> oldMap) {
        CDdSocialPostTriggerHelper.updateSocialCases(newList);
    }
    public void afterInsert(List<SocialPost> newList) {
        CDdSocialPostTriggerHelper.assignSocialCasesToQueues(newList, null);
        CDdSocialPostTriggerHelper.updateDMIndoundOnCase(newList);
    }
    public void afterUpdate(List<SocialPost> newList, Map<Id, SocialPost> oldMap) {

    }
}