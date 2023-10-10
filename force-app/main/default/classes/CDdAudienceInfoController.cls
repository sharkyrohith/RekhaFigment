/**
 * @author   Mahesh Chouhan
 * @date  Nov 18, 2022
 * @decription Controller for lwcDdAudienceInfo Lightning Web Component
 *
 */
public class CDdAudienceInfoController {

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author Mahesh Chouhan
     * @date  Nov 18, 2022
     * @decription Returns Cx, Dx, Mx and Delivery Audience Info
     * @param   {String} caseId - Id of case record
     * @return  List<AudienceInfo>
     */
    @AuraEnabled(cacheable=true)
    public static List<AudienceInfo> getAudienceInfo(String caseId) {
        List<AudienceInfo> audienceInfoList = new List<AudienceInfo>();
        try {
            List<Audience_Info_Configuration__mdt> audienceInfoConfigList = new List<Audience_Info_Configuration__mdt>();
            for(Audience_Info_Configuration__mdt audienceInfoConfig : Audience_Info_Configuration__mdt.getAll().values()){
                if(audienceInfoConfig.Is_Active__c) {
                    audienceInfoConfigList.add(audienceInfoConfig);
                }
            }

            List<Case> cases = CasesSelector.newInstance().selectById(new Set<Id>{ caseId }, new Set<String>{'DispatchRQResponse__c'});

            if(cases.isEmpty() || audienceInfoConfigList.isEmpty()){
                return audienceInfoList;
            }

            for(Audience_Info_Configuration__mdt audienceInfoConfig : audienceInfoConfigList){
                String fieldValue = new DispatchResponseEvaluator().getDispatchAttributeValue(cases[0].DispatchRQResponse__c, audienceInfoConfig.Audience_Field__c);
                audienceInfoList.add(new AudienceInfo(audienceInfoConfig.Type__c, fieldValue, audienceInfoConfig.Audience_Label__c, audienceInfoConfig.Sort_Order__c));
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + e.getStackTraceString());
        }
        audienceInfoList.sort();
        return audienceInfoList;
    }

    /**
     * @description Wrapper for Audience Info
     */
    public class AudienceInfo implements Comparable{
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public String value {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public Decimal sortOrder {get; set;}

        public AudienceInfo(String type, String value, String label, Decimal sortOrder){
            this.type = type;
            this.value = value;
            this.label = label;
            this.sortOrder = sortOrder;
        }

        public Integer compareTo(Object compareTo) {
            AudienceInfo compareToAudienceInfo = (AudienceInfo)compareTo;
            
            return sortOrder > compareToAudienceInfo.sortOrder ? 1 : (sortOrder < compareToAudienceInfo.sortOrder ?
            -1 : 0);
        }
    }

    /**
     * @description Class to Evaluate Dispatch Response
     */
    public class DispatchResponseEvaluator extends CDdCriterionEvaluator {
        public String getDispatchAttributeValue(String dispatchResponse, String attributeName){
            return getDispatchAttribute(dispatchResponse,attributeName);
        }
    }
}