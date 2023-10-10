/**
 *
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Social Post trigger handler helper  migration from old VSocialPost
 *
 */
public class CDdSocialPostTriggerHelper {
    public static Integer followerCount = 9999;
    public static Set<String> doordashTopicProfileNames = new Set<String>{'@doordash_help', '@DoorDash', 'DoorDash', 'doordash', 'SCS DoorDash',
        																'DoorDash (Default)', 'doordash_aus', 'DoorDash Australia' ,'Doordash not tagged' ,
        																'Twitter', 'DoorDash New Zealand', 'Legal 2', 'doordashnz'};
    public static Set<String> caviarTopicProfileNames = new Set<String>{'@CaviarSupport', '@Caviar', 'trycaviar', 'Caviar'};


    // Assign Case to Queues related to Social segments
    public static void assignSocialCasesToQueues(List<SocialPost> socialPostList, Map<id,SocialPost> socialPostMap){
        Map<String,vSocial_Post_Queue_Mapping__c> queueMapping = vSocial_Post_Queue_Mapping__c.getAll();

        Set<String> queueAPINames = new Set<String>();
        // Make sure we have all queues setup in this custom setting.
        for(vSocial_Post_Queue_Mapping__c socialMapping : queueMapping.values()){
             if(String.isNotBlank(socialMapping.Queue_API_Name__c) ){
                 queueAPINames.add(socialMapping.Queue_API_Name__c);
             }
        }

        //System.debug(LoggingLevel.ERROR, ' ===> queueAPINames '+queueAPINames);

        Map<String, Group> queuesWithIds = new Map<String, Group>();
        for(Group queueRec : [  SELECT  Id,
                                        DeveloperName,
                                        Name
                                FROM Group
                                WHERE DeveloperName in:queueAPINames
                                    AND Type='Queue']){
             queuesWithIds.put(queueRec.DeveloperName, queueRec);
        }

        //System.debug(LoggingLevel.ERROR, ' ===> queuesWithIds '+queuesWithIds);

        if(queueMapping != null)
        {
            Set<Id> caseIds = new Set<Id>();
            for(SocialPost post : socialPostList){
                if (doordashTopicProfileNames.contains(post.TopicProfileName)){
                    if(post.ParentId != null && String.valueOf(post.parentId).startsWith('500')){
                        caseIds.add(post.ParentId);
                    } else {
                        System.debug(LoggingLevel.ERROR, 'Post without parent: post = ' + post);
                    }
                }
            }

            //System.debug(LoggingLevel.ERROR, ' ===> caseIds '+caseIds);

            if (caseIds.size() > 0){

                List<Case> casesToUpdate = new List<Case>();
                for(Case caseRec : [SELECT  Id,
                                            Status,
                                            OwnerId,
                                            Original_Sentiment__c,
                                            Social_Post_Type__c,
                                            Initial_Queue__c,
                                            Initial_Queue_Name__c,
                                            (SELECT id,
                                                    MessageType,
                                                    Sentiment,
                                                    Provider,
                                                    PostTags
                                            FROM Posts
                                            ORDER BY CreatedDate ASC LIMIT 1)
                                    FROM Case
                                    WHERE Id in:caseIds
                                    AND Status = 'Open']){
                    //System.debug(LoggingLevel.ERROR, ' ===> caseRec '+caseRec);
                    //System.debug(LoggingLevel.ERROR, ' ===> caseRec.Posts '+caseRec.Posts);

                    // If there are two social posts then case is already assigned to queue. Don't re-assign
                    /*
                    *  [JN-NOTE]: 11/08/17 - If there are two posts being sent at the same time, then they
                    *                        will miss those posts with the previous code. Also, with this,
                    *                        we can use one of the fields as the new source of truth. This
                    *                        will insure more accurate results and predictability
                    */
                    if(caseRec.Posts != null
                        && (caseRec.Initial_Queue__c == null
                            || String.isBlank(caseRec.Initial_Queue__c))){
                        SocialPost post = caseRec.Posts[0];
                        caseRec.Social_Post_Type__c = post.MessageType;
                        caseRec.Original_Sentiment__c = post.Sentiment;

                        Group queue;
                        Boolean isHighPriority = false;
                        if ('Twitter'.equals(post.Provider)
                                    && (post.PostTags != null
                                    && post.PostTags.contains('Twitter Influencer'))) {
                            queue = queuesWithIds.get(System.label.vSocial_VIP);
                            isHighPriority = true;
                        } else if('Twitter'.equals(post.Provider)
                            && (post.PostTags != null
                            && post.PostTags.contains('Twitter Campaign'))) {
                            queue = queuesWithIds.get(System.label.vTwitter_Campaign);
                        } else if('Tweet'.equals(post.MessageType)
                                    || 'Retweet'.equals(post.MessageType)
                                    || ('Twitter'.equals(post.Provider)
                                    && 'Reply'.equals(post.MessageType))) {
                            queue = queuesWithIds.get(System.label.vTwitter_Post);
                        } else if('Twitter'.equals(post.Provider)
                                  && 'Direct'.equals(post.MessageType)) {
                            queue = queuesWithIds.get(System.label.vTwitter_DM);
                        } else if(  ('Facebook'.equals(post.Provider)
                                        && 'Post'.equals(post.MessageType))
                                    || ('Facebook'.equals(post.Provider)
                                        && 'Comment'.equals(post.MessageType))
                                    || ('Facebook'.equals(post.Provider)
                                    && 'Reply'.equals(post.MessageType))) {
                            queue = queuesWithIds.get(System.label.vFacebook_Post);
                        } else if('Private'.equals(post.MessageType)) {
                            queue = queuesWithIds.get(System.label.vFacebook_Message);
                        } else if(('Instagram'.equals(post.Provider)
                                        && 'Post'.equals(post.MessageType))
                                    || ('Instagram'.equals(post.Provider)
                                        && 'Comment'.equals(post.MessageType))
                                 	|| ('Instagram'.equals(post.Provider)
                                        && 'Direct'.equals(post.MessageType))
                                 	|| ('Instagram'.equals(post.Provider)
                                        && 'Reply'.equals(post.MessageType))) {
                            queue = queuesWithIds.get(System.label.vInstagram_Post);
                        }
                        if (queue != null) {
                            caseRec.Initial_Queue__c = queue.Id;
                            caseRec.Initial_Queue_Name__c = queue.Name;
                            caseRec.ownerId = queue.Id;
                            if (isHighPriority){
                                caseRec.Priority = 'High';
                            }
                            casesToUpdate.add(caseRec);
                        }
                    }
                }

                if (casesToUpdate.size() > 0){
                    update casesToUpdate;
                }
            }
        }
    }

    /**
    * @author Sanidhya Jain
    * @date 2023-05
    *
    * @description 	Update DM Indound on case depending on Social Post isourbound field value
    */
    public static void updateDMIndoundOnCase(List<SocialPost> newSPosts){
        List<Id> caseIdList = new List<Id>();
        Map<Id, SocialPost> sPostMap = new Map<Id, SocialPost>();
        for (SocialPost sp : newSPosts){
            if (sp.PersonaId != null){
                caseIdList.add(sp.ParentId);
                sPostMap.put(sp.ParentId, sp);
            }
        }


        if (caseIdList.size() > 0){
            List<Case> caseList = [ select  Id,
                                            DM_Inbound__c,
                                            Last_Social_Inbound_Subject__c
                                    from Case
                                    where Id =: caseIdList];

            for (Case c: caseList){
                if(sPostMap.get(c.id).isOutbound == false){
                    c.Last_Social_Inbound_Subject__c = sPostMap.get(c.Id).Name;
                    c.DM_Inbound__c = true;
                }else{
                    c.DM_Inbound__c = false;
                }
            }
            update caseList;
        }
    }

    /**
    * @author Tia Xuan
    * @date 2019-05
    *
    * @description 	Convert PB to Trigger (vReopen Social Case w/ Post Inbounds),
    * 				the Update Social Influencer action
    */
    /*public static void updateSocialInfluencer(List<SocialPost> newSPosts){
        List<Id> personaIdList = new List<Id>();
        List<SocialPost> spList = new List<SocialPost>();
        for (SocialPost sp : newSPosts){
            if (sp.PersonaId != null
                    && sp.isOutbound == false){
                personaIdList.add(sp.PersonaId);
                spList.add(sp);
            }
        }

        Map<Id, SocialPersona> personaMap = new Map<Id, SocialPersona>([select 	Id,
                IsVerified,
                Followers
        from SocialPersona
        where Id = : personaIdList]);

        for (SocialPost sp : spList){
            SocialPersona p = personaMap.get(sp.PersonaId);
            if (p != null
                    && (p.IsVerified
                    || p.Followers > followerCount)){
                sp.Social_Influencer__c = true;
            } else {
                sp.Social_Influencer__c = false;
            }
        }
    }*/

    /**
     * Update and route cases generated by Social.InboundSocialPostHandlerImpl to include additional information
     * from the SocialPost.
     *
     * @param List<SocialPost> posts
    */
    public static void updateSocialCases(List<SocialPost> posts) {
        Set<Id> caseIds = new Set<Id>();
        List<Case> cases = new List<Case>();
        Id caviarCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Caviar_Support').getRecordTypeId();
        Id doordashCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        Group owner = [  select Id, Name
                        from Group
                        where DeveloperName = 'Caviar_Social_Support'
                            and Type = 'Queue'];

        Map<Id, SocialPost> caseIdToPost = new Map<Id, SocialPost>();
        // Get a list of cases and contacts associated with these posts
        for (SocialPost post : posts) {
            if(post.ParentId != null && String.valueOf(post.parentId).startsWith('500')) {
                caseIds.add(post.ParentId);
                caseIdToPost.put(post.ParentId, post);
            } else {
                System.debug(LoggingLevel.ERROR, 'Post without parent: post = ' + post);
            }
        }

        for (Case caseRec : [select Id,
                                    Status,
                                    Initial_Queue__c
                            from Case
                            where Id in : caseIds
                                and Status in ('New', 'Open')]) {
            SocialPost sp = caseIdToPost.get(caseRec.Id);
            if (caviarTopicProfileNames.contains(sp.TopicProfileName)){
                if (sp != null && caseRec.Initial_Queue__c == null) {
                    caseRec.Priority = sp.PostPriority;
                    caseRec.Subject = getSubjectFromTags(sp.PostTags);
                }
                caseRec.Initial_Queue__c = owner.Id;
                caseRec.Initial_Queue_Name__c = owner.Name;
                caseRec.OwnerId = owner.Id;
                caseRec.RecordTypeId = caviarCaseRecordType;
                caseRec.Type = 'Caviar Social';
                caseRec.Channel__c = 'Caviar Social';
                caseRec.Platform__c = 'Caviar';


                cases.add(caseRec);
            } else if (doordashTopicProfileNames.contains(sp.TopicProfileName)) {
                caseRec.RecordTypeId = doordashCaseRecordType;
                caseRec.Channel__c = 'DoorDash Social';
                caseRec.Platform__c = 'DoorDash';
                cases.add(caseRec);
            }
        }
        update cases;
    }

    /**
     * Create a Case.Subject value by concatenating postTags, which are defined as "subject" tags by custom metadata,
     *
     * @param postTags A comma-separated list of all post tags
     *
     * @return An ordered and concatenated subject line
     */
    private static String getSubjectFromTags(String postTags) {
        String subject = '';
        List<String> allTags = new List<String>();
        List<String> subjectOnlyTags = new List<String>();

        if (postTags != null) {
            for (String tag : postTags.split(',', 0)) {
                allTags.add(tag.trim());
            }
            for (String mdtSubject : getSubjectsFromMetadata()) {
                if (allTags.contains(mdtSubject)) {
                    subjectOnlyTags.add(mdtSubject);
                }
            }
            subject = String.join(subjectOnlyTags, ' - ');
        }
        return subject;
    }

    /**
     * Retrieve an ordered list of valid case subjects from custom metadata
     *
     * @return Set<String>
     */
    private static Set<String> getSubjectsFromMetadata() {
        Set<String> labels = new Set<String>();
        Set<Social_Post_Subject__mdt> subjects = new Set<Social_Post_Subject__mdt>(
            [select Label, Order__c from Social_Post_Subject__mdt order by Order__c]);

        for (Social_Post_Subject__mdt subject : subjects) {
            labels.add(subject.Label);
        }
        return labels;
    }

}