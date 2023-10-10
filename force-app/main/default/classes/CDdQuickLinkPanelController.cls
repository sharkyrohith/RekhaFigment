/**
 * @author   Mahesh Chouhan
 * @date  Nov 17, 2022
 * @decription Controller for lwcDdQuickLinkPanel Lightning Web Component
 *
 */
public class CDdQuickLinkPanelController {

    /*****************************************************************************************************************************
     *
     * Public Methods
     *
     *****************************************************************************************************************************/
    /**
     * @author Mahesh Chouhan
     * @date  Nov 17, 2022
     * @decription Returns Quick Link CMT for specified object
     * @param   {String} objectApiName - name of the object of lightning record page
     * @return  List<QuickLink>
     */
    @AuraEnabled(cacheable=true)
    public static List<QuickLink> getQuickLinkConfiguration(String objectApiName, Id recordId){
        List<QuickLink> quickLinkConfigList = new List<QuickLink>();
        try {
            Set<String> fields = new Set<String>();
            List<Quick_Link_Configuration__mdt> casesQuickLinkConfigs = new List<Quick_Link_Configuration__mdt>();
            for(Quick_Link_Configuration__mdt quickLinkConfig : Quick_Link_Configuration__mdt.getAll().values()){
                if(quickLinkConfig.Object__c == objectApiName && quickLinkConfig.Is_Active__c){
                    if(quickLinkConfig.Quick_Link_URL__c.contains('{')){
                        fields.add(quickLinkConfig.Quick_Link_URL__c.subStringAfter('{').removeEnd('}'));
                        casesQuickLinkConfigs.add(quickLinkConfig);   
                    }
                }
            }

            if(casesQuickLinkConfigs.size() > 0){
                List<Case> caseRecord = CasesSelector.newInstance().selectById(new Set<Id>{recordId}, fields);
                if(caseRecord.size() > 0) {
                    for(Quick_Link_Configuration__mdt quickLinkConfig : casesQuickLinkConfigs){
                        String url = CDdUtilities.replaceMergeFieldsString(caseRecord[0], quickLinkConfig.Quick_Link_URL__c);
                        if(!url.equals(quickLinkConfig.Quick_Link_URL__c)) {
                            quickLinkConfigList.add(new QuickLink(quickLinkConfig.Id, url, quickLinkConfig.Quick_Link_Label__c, quickLinkConfig.Customer_Type__c));
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return quickLinkConfigList;
    }

    /**
     * @description Wrapper for Quick Links
     */
    public class QuickLink {
        @AuraEnabled
        public String id {get; set;}
        @AuraEnabled
        public String url {get; set;}
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public String customerType {get; set;}

        public QuickLink(String id, String url, String label, String customerType){
            this.id = id;
            this.url = url;
            this.label = label;
            this.customerType = customerType;
        }
    }
}