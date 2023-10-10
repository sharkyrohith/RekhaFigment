// ===========================================================================
// Component: CDdCrossSkillingFinderController
// Author: Nayana Kapse
// Purpose: This is used to find cross skilling for a specific queue
// ===========================================================================
public class CDdCrossSkillingFinderController {
    public static Set<String> vendorNames = new Set<String>();

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get all the Omni Enabled Queues
    */
    @AuraEnabled( cacheable = true )
    public static PicklistWrapper getOmniEnabledQueues() {
        PicklistWrapper retVal = new PicklistWrapper();
        List<CDdPicklistUtil.PicklistOption> queueOptions = new List<CDdPicklistUtil.PicklistOption>();
        List<CDdPicklistUtil.PicklistOption> vendorOptions = new List<CDdPicklistUtil.PicklistOption>();
        for(Group grp: [SELECT Id,Name,DeveloperName,QueueRoutingConfigId FROM Group WHERE Type = 'Queue' AND Id IN:setVendorSplitQueues ]){
            CDdPicklistUtil.PicklistOption queueOption = new CDdPicklistUtil.PicklistOption(grp.Name,grp.DeveloperName);
            queueOptions.add(queueOption);
        }
        retVal.queueOptions = queueOptions;
        for(String vendorName: mapVendorUserMapping.keySet()){
            CDdPicklistUtil.PicklistOption vendorOption = new CDdPicklistUtil.PicklistOption(vendorName,vendorName);
            vendorOptions.add(vendorOption);
        }
        retVal.vendorOptions = vendorOptions;
        return retVal;
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get all case object queues
    */
    @AuraEnabled( cacheable = true )
    public static PicklistWrapper getCaseObjectQueues() {
        PicklistWrapper retVal = new PicklistWrapper();
        List<CDdPicklistUtil.PicklistOption> queueOptions = new List<CDdPicklistUtil.PicklistOption>();
        List<CDdPicklistUtil.PicklistOption> vendorOptions = new List<CDdPicklistUtil.PicklistOption>();
        for(Group grp: [SELECT Id,Name,DeveloperName,QueueRoutingConfigId,(SELECT SobjectType
            FROM QueueSobjects WHERE SobjectType = 'Case') FROM Group WHERE Type = 'Queue']){
            CDdPicklistUtil.PicklistOption queueOption = new CDdPicklistUtil.PicklistOption(grp.Name,grp.DeveloperName);
            queueOptions.add(queueOption);
        }
        retVal.queueOptions = queueOptions;
        for(String vendorName: mapVendorUserMapping.keySet()){
            CDdPicklistUtil.PicklistOption vendorOption = new CDdPicklistUtil.PicklistOption(vendorName,vendorName);
            vendorOptions.add(vendorOption);
        }
        retVal.vendorOptions = vendorOptions;
        return retVal;
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get map of vendor name and list of email domains
    */
    public static Map<String,Set<String>> mapVendorUserMapping {
        get {
            if(mapVendorUserMapping == null) {
                mapVendorUserMapping = new Map<String,Set<String>>();
                for(Vendor_User_Mapping__mdt rec : Vendor_User_Mapping__mdt.getAll().values()){
                    Set<String> allEmailDomainsinVum =new Set<String>();
                    if(!mapVendorUserMapping.containsKey(rec.Company_Name__c)){
                        mapVendorUserMapping.put(rec.Company_Name__c,new Set<String>());
                    }
                    allEmailDomainsinVum.addAll(rec.Email_Domain_Prefixes__c.split('\n'));
                    mapVendorUserMapping.get(rec.Company_Name__c).addAll(allEmailDomainsinVum);
                    vendorNames.add(rec.Company_Name__c);
                }
            }
            return mapVendorUserMapping;
        }
        private set;
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get map of email domain vs vendor name
    */
    public static Map<String,String> mapDomainVendorMapping {
        get {
            if(mapDomainVendorMapping == null) {
                mapDomainVendorMapping = new Map<String,String>();
                for(Vendor_User_Mapping__mdt rec : Vendor_User_Mapping__mdt.getAll().values()){
                    for(String domain: rec.Email_Domain_Prefixes__c.split('\n')){
                        mapDomainVendorMapping.put(domain,rec.Company_Name__c);
                    }
                }
            }
            return mapDomainVendorMapping;
        }
        private set;
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get set of vendor split queues
    */
    public static Set<Id> setVendorSplitQueues {
        get{
            if(setVendorSplitQueues == null) {
                setVendorSplitQueues = new Set<Id>();
                for (Support_Assignment_Mapping__c sam : Support_Assignment_Mapping__c.getAll().values()){
                    setVendorSplitQueues.add(sam.Queue_Id__c);
                }
            }
            return setVendorSplitQueues;
        }
        private set;
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description get VendorUserDetailWrapper
    * @param : queueDevName : Queue Developer Name
    *          vendorName   : Vendor Name
    * @return: VendorUserDetailWrapper
    */
    @AuraEnabled
    public static VendorUserDetailWrapper findCrossSkilling(String queueDevName,String vendorName) {
        try{
            VendorUserDetailWrapper retVal = new VendorUserDetailWrapper();
            Set<Id> agentIds = new Set<Id>();
            Map<Id,User> mapIdUser = new Map<Id,User>();
            Map<String,Integer> mapDomainCount = new Map<String,Integer>();
            Map<String,List<User>> mapDomainUser = new Map<String,List<User>>();
            Set<String> allEmailDomainsinVumTrimmed = new Set<String>();
            List<UserWrapper> lstUsrWrapper = new List<UserWrapper>();
            Set<Id> userIdsOfDiffDomain = new Set<Id>();
            Map<String,List<User>> mapAgentsToDiffQueues = new Map<String,List<User>>();
            Id groupId;
            //get all the agents under this queue
            for(GroupMember gm : [SELECT Id,UserOrGroupId,group.name,Group.Id FROM GroupMember WHERE Group.DeveloperName = :queueDevName]){
                agentIds.add(gm.UserOrGroupId);
                groupId = gm.Group.Id;
            }
            setVendorSplitQueues.remove(groupId);

            for(User usr: [SELECT Id,Email,UserRole.Name,CompanyName FROM User WHERE Id IN:agentIds AND isActive= true]){
                String emaildomain = usr.email.split('@')[1].trim();
                Integer countVal =   !mapDomainCount.containsKey(emaildomain) ? 0 :  mapDomainCount.get(emaildomain);
                countVal += 1;
                mapDomainCount.put(emaildomain,countVal);
                if(!mapDomainUser.containsKey(emaildomain)){
                    mapDomainUser.put(emaildomain,new List<User>());
                }
                mapDomainUser.get(emaildomain).add(usr);
                mapIdUser.put(usr.Id,usr);
            }

            for(String rec : mapVendorUserMapping.get(vendorName)){
                allEmailDomainsinVumTrimmed.add(rec.trim());
            }

            for(String em : mapDomainUser.keyset()){
                if(!allEmailDomainsinVumTrimmed.contains(em.trim()) && !mapDomainVendorMapping.containsKey(em.trim())){
                    retVal.mapNewDomainWithUserCount.put(em.trim(),mapDomainCount.get(em));
                }else if(!allEmailDomainsinVumTrimmed.contains(em.trim())){
                    List<User> lstUsers = new List<User>();
                    for(User u: mapDomainUser.get(em)){
                        if(!vendorName.equalsIgnoreCase(u.CompanyName)){
                            lstUsers.add(u);
                            UserWrapper wrp = new UserWrapper(u);
                            lstUsrWrapper.add(wrp);
                            userIdsOfDiffDomain.add(u.Id);
                        }
                    }
                    retVal.mapDiffDomainWithUsers.put(mapDomainVendorMapping.get(em.trim()),lstUsers);
                }
            }

            Boolean isVendorQueue = false;
            for(GroupMember memb : [SELECT Id, UserOrGroupId, Group.Name
                                    FROM GroupMember
                                    WHERE UserOrGroupId in :mapIdUser.keySet()
                                    AND GroupId in :setVendorSplitQueues]) {
                User u = mapIdUser.get(memb.UserOrGroupId);
                isVendorQueue = false;
                for(String str: vendorNames){
                    if(memb.Group.Name.containsIgnoreCase(str)){
                        isVendorQueue= true;
                        break;
                    }
                }
                //Relying on Queue name to determine the vendor, which could be wrong if naming convention not followed.
                if(!memb.Group.Name.containsIgnoreCase(vendorName) && isVendorQueue && !userIdsOfDiffDomain.contains(u.Id)){
                    if(!mapAgentsToDiffQueues.containsKey(memb.Group.Name)){
                        mapAgentsToDiffQueues.put(memb.Group.Name,new List<User>());
                    }
                    mapAgentsToDiffQueues.get(memb.Group.Name).add(u);
                    UserWrapper wrp = new UserWrapper(u);
                    lstUsrWrapper.add(wrp);
                }
            }
            retVal.mapAgentsAddedToDifferentQueues = mapAgentsToDiffQueues;
            retVal.lstUserWrapper = lstUsrWrapper;
            return retVal;
        }catch(Exception e){
            throw e;
        }
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description PicklistWrapper(Queue and Vendor picklist values)
    *
    */
    public class PicklistWrapper {
        @AuraEnabled public List<CDdPicklistUtil.PicklistOption> queueOptions = new List<CDdPicklistUtil.PicklistOption>();
        @AuraEnabled public List<CDdPicklistUtil.PicklistOption> vendorOptions = new List<CDdPicklistUtil.PicklistOption>();
    }

    /**
    * @author: Nayana Kapse
    * @date: 07-2023
    * @description VendorUserDetailWrapper(New domain map with user count assigned to this new domain,
    *                  Users from different vendor,User wrapper for export)
    *
    */
    public class VendorUserDetailWrapper {
        @AuraEnabled public Map<String,Integer> mapNewDomainWithUserCount = new Map<String,Integer>();
        @AuraEnabled public Map<String,List<User>> mapDiffDomainWithUsers = new Map<String,List<User>>();
        @AuraEnabled public List<UserWrapper> lstUserWrapper = new List<UserWrapper>();
        @AuraEnabled public Map<String,List<User>> mapAgentsAddedToDifferentQueues = new Map<String,List<User>>();
    }

    // wrapper class for user search result
    public class UserWrapper {
        @auraEnabled
        public String id {get; set;}
        @auraEnabled
        public String email {get; set;}
        @auraEnabled
        public String role {get; set;}

        public UserWrapper(User usr) {
            this.id = usr.Id;
            this.email = usr.Email;
            this.role = usr.UserRole.Name;
        }
    }
}