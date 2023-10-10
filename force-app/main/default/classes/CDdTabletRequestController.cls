/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 6/13/2020.
 *
 * Implements: BZAP-6766 Tablet Request Case Grid
 *
 * Display related tablet cases in a grid that can be used by Classic and Lightning
 */
public with sharing class CDdTabletRequestController {

    /**
     * Get a list of related tablet request cases and wrap them in a CaseObject for display in a
     * lightning data table.
     *
     * @param caseId The case for which to find related cases (by AccountId)
     * @return CaseObject A Case wrapper object
     */
    @AuraEnabled
    public static List<CaseObject> getCases(Id caseId) {
        Case sourceCase = [select AccountId from Case where Id = :caseId];

        List<Case> cases = [
                select
                    CaseNumber,
                    Id,
                    Opportunity_Name_External_Use__c,
                    Opportunity_Name__c,
                    Request_Type__c,
                    Status,
                    Tablet_Received_Date_2__c,
                    Tablet_Ship_Date2__c,
                    Tablet_Shipment_Status__c,
                    Track_Status__c
            from Case where AccountId = :sourceCase.AccountId and RecordTypeId = :CDdSchemaUtils.CASE_RT.tabletRequestsId()];

        List<CaseObject> objects = new List<CaseObject>();
        for (Case targetCase : cases) { objects.add(new CaseObject(targetCase)); }

        return objects;
    }

    /**
     * CaseObject is a Case wrapper with additional fields for rendering URLs
     */
    public class CaseObject {
        @AuraEnabled public final Datetime Tablet_Received_Date_2;
        @AuraEnabled public final Datetime Tablet_Ship_Date2;
        @AuraEnabled public final String ClaimLink;
        @AuraEnabled public final String ClaimNo;
        @AuraEnabled public final String OpportunityLink;
        @AuraEnabled public final String Opportunity_Name_External_Use;
        @AuraEnabled public final String Request_Type;
        @AuraEnabled public final String Status;
        @AuraEnabled public final String Tablet_SIM_Card_Number;
        @AuraEnabled public final String Tablet_Shipment_Status;
        @AuraEnabled public final String Track_Status;

        public CaseObject(Case cas) {
            this.ClaimLink = Url.getSalesforceBaseUrl().toExternalForm() + '/' + cas.Id;
            this.ClaimNo = cas.CaseNumber;
            this.OpportunityLink = Url.getSalesforceBaseUrl().toExternalForm() + '/' + cas.Opportunity_Name__c;
            this.Opportunity_Name_External_Use = cas.Opportunity_Name_External_Use__c;
            this.Request_Type = cas.Request_Type__c;
            this.Status = cas.Status;
            this.Tablet_Received_Date_2 = cas.Tablet_Received_Date_2__c;
            this.Tablet_Ship_Date2 = cas.Tablet_Ship_Date2__c;
            this.Tablet_Shipment_Status = cas.Tablet_Shipment_Status__c;
            this.Track_Status = extractUrl(cas.Track_Status__c);
        }

        /**
         * @param href e.g. '<a href="http://wwwapps.ups.com/etracking/tracking.cgi?tracknums_displayed=1&amp;TypeOfInquiryNumber=T&amp;HTMLVersion=4.0&amp;InquiryNumber1=" target="_blank">Track  - </a>'
         * @return url e.g. 'http://wwwapps.ups.com/etracking/tracking.cgi?tracknums_displayed=1&amp;TypeOfInquiryNumber=T&amp;HTMLVersion=4.0&amp;InquiryNumber1='
         */
        private String extractUrl(String href) {
            String url = '';
            Matcher mat = Pattern.compile('(.*)(http[^"]*)(.*)').matcher(href);
            if (mat.matches()) {
                url = mat.group(2);
            }
            return url;
        }
    }
}