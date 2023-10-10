/**
* CDdCaseVendorSplitEventHelper
*
* @author      Sahil (sahil.chaudhry@doordash.com)
* @date        08/10/2021
* @decription  this class has the operations for processing case vendor split platform event
*/
public with sharing class CDdCaseVendorSplitEventHelper {
    /*****************************************************************************************************************************
    *
    * Public/Global Variables
    *
    *****************************************************************************************************************************/
    public enum OperationType {
        INCREMENT_VENDOR_CC, //increment vendor chat count
        TRUE_UP_VD           //true up vendor distribution
    }
    public static final Map<OperationType, String> operationMap = new Map<OperationType, String> {
        OperationType.INCREMENT_VENDOR_CC   => 'Case Increment Vendor CC',
        OperationType.TRUE_UP_VD            => 'Case TrueUp Vendor Distribution'
    };
    public static String strOperation(OperationType oprType) {
        String opTypeString =  operationMap.containsKey(oprType) ? operationMap.get(oprType) : null;
        if (String.isNotBlank(opTypeString)) {
           return opTypeString;
        }
        throw new CDdCaseVendorSplitEventHelperException ('Platform Event Type: ' + oprType + ' not found in platformEventMap.');
    }

    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
    /** 
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    creates case vendor split events
    * @param         operation type, record ids, payload
    * @return        list of case vendor split events
    */
    public static List<Case_Vendor_Split__e> createcvsEvents(OperationType oprType, Set<Id> sObjIdSet, String payload) {
        String operationString = strOperation(oprType);
        List<Case_Vendor_Split__e> eventList = new List<Case_Vendor_Split__e>();
        if(sObjIdSet == null || sObjIdSet.isEmpty()) {
            eventList.add(new Case_Vendor_Split__e(
                Record_ID__c = null,
                Operation__c = operationString,
                Payload__c = payload
            ));
        } else {
            for (Id sobjId : sObjIdSet) {
                eventList.add(new Case_Vendor_Split__e(
                    Record_ID__c = sobjId,
                    Operation__c = operationString,
                    Payload__c = payload
                ));
            }
        }
        return eventList;
    }

    /** 
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    publishes case vendor split events
    * @param         list of case vendor split events
    * @return        None
    */
    public static void publishEvents(List<Case_Vendor_Split__e> eventList) {
        EventBus.publish(eventList);
    }
    
    /** 
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    publishes case vendor split events 
    * @param         operation type, set of record ids, payload on the event
    * @return        None
    */
    public static void publishEvents(OperationType oprType, Set<Id> sobjIds, String payload) {
        publishEvents(createcvsEvents(oprType, sobjIds, payload));
    }
    
    /** 
    * @author        Sahil(sahil.chaudhry@doordash.com)
    * @date          08/02/2021
    * @decription    method to handle the incoming events and call corresponding business methods
    * @param         list of case vendor split events
    * @return        None
    */
    public static void handleEvents(List<Case_Vendor_Split__e > eventList) {
        for (OperationType oprType : operationMap.keySet()) {
            String strOpType = strOperation(oprType);
            List<Case_Vendor_Split__e> typeEvents = new List<Case_Vendor_Split__e>();
            for (Case_Vendor_Split__e event : eventList)
                if (event.Operation__c == strOpType)
                    typeEvents.add(event);
            if (typeEvents.size() > 0) {
                if (oprType == OperationType.TRUE_UP_VD) {
                    CDdVendorSplitHelper.handleUpdateVendorDistribution(typeEvents);
                }
                else if (oprType == OperationType.INCREMENT_VENDOR_CC) {
                    CDdVendorSplitHelper.handleIncrementVendorCCPE(typeEvents);
                }               
            }
        }
    }

    public class CDdCaseVendorSplitEventHelperException extends Exception {}
}