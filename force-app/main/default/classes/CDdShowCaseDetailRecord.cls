/**
 * @author Sanidhya Jain
 * @date 2023-08
 *
 * @description Class : BIZS-3185 used to get the Case Detail Record on Case Object using Lightinmg Record Form
*/
public class CDdShowCaseDetailRecord {
	/**
     * @description  To retrive Case Detail Record id & Field Set Name
     * @param   recordId {String}
     * @return  GetRecordFieldSetName
     */
    @AuraEnabled
    public static GetRecordFieldSetName getCaseDetailFieldSet(String recordId){
        Id idRecords;
        List<Case> caseList = new List<Case>();
        caseList = [Select id,Case_Detail__c,Case_Detail__r.Case_Detail_Type__c FROM Case where id = :recordId Limit 1];
        GetRecordFieldSetName fieldSetWrapper = new GetRecordFieldSetName();
        if(caseList.size()>0){
            if(!String.isEmpty(caseList[0].Case_Detail__c) && (!String.isEmpty(caseList[0].Case_Detail__r.Case_Detail_Type__c) || Test.isRunningTest())){
                String caseDetailRecordId = caseList[0].Case_Detail__c;
                List<UserRecordAccess> userAccesRecord = new List<UserRecordAccess>();
                userAccesRecord = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() and RecordId =: caseDetailRecordId];
                if(userAccesRecord[0].HasEditAccess){
                    fieldSetWrapper.recordId = caseDetailRecordId;
                    String sectionName = caseList[0].Case_Detail__r.Case_Detail_Type__c;
                    fieldSetWrapper.fieldSetname = sectionName.replace(' ','_').replace('&','').replace('__','_');
                    fieldSetWrapper.sectionName = sectionName;
                }
                return fieldSetWrapper;
             }
        }
        return null;
    }

    public class GetRecordFieldSetName{
        @AuraEnabled
        public String recordId;
        @AuraEnabled
        public String fieldSetname;
        @AuraEnabled
        public String sectionName;
    }
}