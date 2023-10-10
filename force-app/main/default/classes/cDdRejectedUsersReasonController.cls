/**
 * cDdRejectedUsersReasonController
 *
 * @author     Shiva
 * @date  2020-04-16
 * @decription controller class for LddRejectedUsersReason & LddUserRejectReason
 */
public with sharing class cDdRejectedUsersReasonController {
    
    /**
    @author Shiva
    @Date 2021-04-16
    @decription used to save rejected review reason on change on the UI
    @param UserReviewId to save and rejectedReason to update the Rejected_Reason__c picklist
    @return Boolean true if save successfull or exception thrown
    */
	@AuraEnabled
    public static Boolean saveUserReviewReason(String userReviewId, String rejectedReason){
        try {
            User_Review__c ur = new User_Review__c();
            ur.Id=userReviewId;
            ur.Rejected_Reason__c=rejectedReason;
            update ur;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
    @author Shiva
    @Date 2021-04-16
    @decription used to save Approval status on change on the UI
    @param UserReviewId to save and approvalStatus to update the Approval_Status__c picklist
    @return Boolean true if save successfull or exception thrown
    */
    @AuraEnabled
    public static Boolean saveUserReviewStatus(String userReviewId, String approvalStatus){
        try {
            User_Review__c ur = new User_Review__c();
            ur.Id=userReviewId;
            ur.Approval_Status__c =approvalStatus;
            ur.Date_Reviewed__c =date.today();
            update ur;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
}