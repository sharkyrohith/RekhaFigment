/**
 *
 * @author: Nayana Kapse
 * @date: 2021-11
 * @description class for CDdSupportOwnerAssignment - Find the owner for Chat/Case
 *
 */
public with sharing class CDdSupportOwnerAssignment {
    /*****************************************************************************************************************************
     *
     * Constants & Private Variables
     *
    *****************************************************************************************************************************/
    @TestVisible private static String overflowReason = CDdRoutingOverflowHelper.mapQueueMetadata.containsKey('Routing_Reason') ?
    CDdRoutingOverflowHelper.mapQueueMetadata.get('Routing_Reason').Value__c : '';
    @TestVisible private Map<Id,CDdRoutingOverflowHelper.QueueCacheWrapper> mapQueueCache = CDdRoutingOverflowHelper.getQueueCacheData();

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/

    /**
    * @author        TO DO
    * @date
    * @decription    Based on object type and key find out the owner
    * @param         key: Issue_Based Routing+prefered vendor+VIP etc
                     objectName : Case/Chat
    * @return        OwnerRoutingInfo : wrapper with final OwnerId and if owner is replaced with Overflow queue Id then overflow reason
    */
    public OwnerRoutingInfo findOwner(String objectName,String key) {
        //This method will use key and check the Support Assignment Mapping	to find the Queue Id
        //Them call findFinalOwner(queueId) to get the final queueId as owner and return
        return new OwnerRoutingInfo();
    }

    /**
    * @author        Nayana
    * @date          11/01/2021
    * @decription    Checks if for original Queue overflow is enabled and reached
    * @param         originalOwnerId: QueueID for which we need to check overflow
    * @return        OwnerRoutingInfo : wrapper with final OwnerId and if owner is replaced with Overflow queue Id then overflow reason
    */
    public OwnerRoutingInfo findFinalOwner(Id originalOwnerId) {
        OwnerRoutingInfo oInfo = new OwnerRoutingInfo();
        oInfo.ownerId = originalOwnerId;
        Id overflowQueueId = getOverflowId(originalOwnerId);
        if(!overflowQueueId.equals(originalOwnerId)){
            oInfo.ownerId = overflowQueueId;
            oInfo.routingReason = overflowReason;
        }
        return oInfo;
    }

    /**
    * @author Nayana
    * @date: 2021-09
    * @description this method is used to find overflow queue
    * @param queueId: QueueID for which we need to check overflow
    * @return Id: OriginalQueue ID/Overflow Queue ID based on Overflow occured or not
    * @jira BIZS-439
    */
    private Id getOverflowId(Id queueId) {
        Id overflowQueueId = queueId;
        CDdRoutingOverflowHelper.QueueCacheWrapper qCacheWrap = new CDdRoutingOverflowHelper.QueueCacheWrapper();
        if(!mapQueueCache.isEmpty() && mapQueueCache.containsKey(queueId)){
            qCacheWrap = mapQueueCache.get(queueId);
            if(qCacheWrap.isQueueOverflow){
                overflowQueueId = qCacheWrap.overflowQueueId;
            }
        }
        return overflowQueueId;
    }


    /**
    * @author        Nayana
    * @date          11/01/2021
    * @decription    Wrapper class to hold Final Owner ID and routing reason
    */
    public class OwnerRoutingInfo {
        public Id ownerId;
        public String routingReason ='';
    }

}