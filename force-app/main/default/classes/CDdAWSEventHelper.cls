/**
 * CDdAWSEventHelper
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       August 2022
 * @decription Helper methods for AWS Platform event AWS_Event__e
*/
public with sharing class CDdAWSEventHelper {
    //get owner's context from cache in case trigger context
    public static Map<Id, User> caseOwnerMap = CDdCaseTriggerOptimizationHelper.getUserMap();
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        August 2022
     * @decription  create AWS Event from case
     * @param       old case, new case
     * @return      instance of AWS_Event__e
    */
    public static AWS_Event__e createAWSEvent(Case caseObj) {
        AWSEventWrapper eventPayload = new AWSEventWrapper(caseObj);
        AWS_Event__e awsEvent = new AWS_Event__e(
            Operation__c = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.OPERATION_PHONE_CASE_UNRESOLVED),
            Payload__c = JSON.serialize(eventPayload)
        );
        return awsEvent;
    }

    /**
     * @author      Sahil Chaudhry
     * @date        August 2022
     * @decription  create AWS Event from case
     * @param       old case, new case
     * @return      instance of AWS_Event__e
    */
    public class AWSEventWrapper{
        public String caseId;
        public String caseOwnerEmail;
        
        public AWSEventWrapper(Case newCase){
            caseId = newCase.Id;
            if (!caseOwnerMap.isEmpty()) {
                caseOwnerEmail = caseOwnerMap.get(newCase.OwnerId).Email;
            }
        }
    }
}