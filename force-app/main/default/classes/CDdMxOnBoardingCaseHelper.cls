/********************************************************************************************************************
* @author Ganesh
* @date
* @group SSMO Mx onboarding
*
* @description BZAP-20577 - Figment Update Case Owner and Status for Milestone changes
*
**************************************************************************************************************************************/
public class CDdMxOnBoardingCaseHelper{

    public static final String MILESTONE_STATUS_COMPLETE = 'Complete';
    public static final String MILESTONE_STATUS_DEAD = 'Dead';
    public static final String MILESTONE_STATUS_BLOCKED = 'Blocked';
    public static final String MILESTONE_STATUS_REASON_FRAUD = 'Fraud';
    public static final string MILESTONE_TYPE_REVIEW_TRIAGE = 'Review & Triage';
    public static final string CASE_STATUS_OPEN = 'Open';
    public static final string CASE_STATUS_INPROGRESS = 'In Progress';
    public static final string STATUS = 'Status';
    public static final string OWNER = 'Owner';
    public static final Id MX_FRAUD_INVESTIGATION_QUEUE_ID;
    static {
        MX_FRAUD_INVESTIGATION_QUEUE_ID = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Mx_Fraud_Investigations'].Id;
    }
    public static final Id ONBOARDING_UNDER_REVIEW_QUEUE_ID;
    static {
        ONBOARDING_UNDER_REVIEW_QUEUE_ID = [SELECT Id, DeveloperName FROM Group WHERE Type = 'QUEUE' AND DeveloperName= 'Onboarding_Under_Review'].Id;
    }
    
    private static final Map<String, Map<String, String>> STATUS_OWNER_MAP =
        new Map<String, Map<String, String>>{
            MILESTONE_STATUS_DEAD => new Map<String, String>{
                STATUS => MILESTONE_STATUS_DEAD,
                OWNER => ONBOARDING_UNDER_REVIEW_QUEUE_ID
            },
            MILESTONE_STATUS_BLOCKED => new Map<String, String>{
                STATUS => MILESTONE_STATUS_BLOCKED,
                OWNER => MX_FRAUD_INVESTIGATION_QUEUE_ID
            },
            MILESTONE_STATUS_COMPLETE => new Map<String, String>{
                STATUS => CASE_STATUS_INPROGRESS,
                OWNER => ONBOARDING_UNDER_REVIEW_QUEUE_ID
            }                        
        };

    public Map <Id, SObject> getsObjectsToUpdate(List<SObject> milestonesList){

        Map<Id, string> caseIdStatusMap = new Map<Id, string>();
        Map <ID, SObject> caseToUpdate = new Map <ID, SObject>();
        for(Milestone__c milestone:(List<Milestone__c>) milestonesList){
            if(milestone.Milestone_Type__c == MILESTONE_TYPE_REVIEW_TRIAGE
                && string.isNotBlank(milestone.Status__c)
                && (milestone.Status__c == MILESTONE_STATUS_COMPLETE 
                || (milestone.Status__c == MILESTONE_STATUS_DEAD 
                    && string.isNotBlank(milestone.Status_Reason__c)
                    && milestone.Status_Reason__c.contains(MILESTONE_STATUS_REASON_FRAUD)
                    )
                || (milestone.Status__c == MILESTONE_STATUS_BLOCKED 
                    && string.isNotBlank(milestone.Status_Reason__c)
                    && milestone.Status_Reason__c.contains(MILESTONE_STATUS_REASON_FRAUD)))){

                caseIdStatusMap.put(milestone.Case__c, milestone.Status__c);
            }
        }

        if(caseIdStatusMap.isEmpty()){
            return caseToUpdate;
        }

        for(Case cs:[SELECT Id, Status, OwnerId FROM Case WHERE Id IN:caseIdStatusMap.keySet() AND RecordType.DeveloperName = 'Marketplace_Onboarding']){
            
            cs.OwnerId = STATUS_OWNER_MAP.get(caseIdStatusMap.get(cs.Id)).get(OWNER);
            cs.Status = STATUS_OWNER_MAP.get(caseIdStatusMap.get(cs.Id)).get(STATUS);
            caseToUpdate.put(cs.Id, cs);
        }

        return caseToUpdate;
    }
}