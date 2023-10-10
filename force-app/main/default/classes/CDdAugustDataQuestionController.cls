/**
 * @author Mahesh Chouhan
 * @date 2022-08
 *
 * @description Controller class for lwcDdAugustDataQuestion
*/

public class CDdAugustDataQuestionController {

    public static final String UNAUTHORIZED_USER_ERROR = 'You are not authorized';
    public static final String AUGUST_DATA_QUESTION_PS = 'August_Data_Question';

    /**
     * @author Mahesh Chouhan
     * @date  2022-08
     * @decription Returns a Boolean if account email or phone is present in August Data Question records
     * @param   accountId - Id of account
     * @return  Boolean - true if Account Email or Phone is present in August Data Question records othewise false
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkAccountImpact(String accountId){
        if(!checkUserAuthorization()) {
            throw new AuraHandledException(UNAUTHORIZED_USER_ERROR);
        }
        List<Account> dasherOrConsumer = [SELECT PersonEmail, Phone
                                          FROM Account
                                          WHERE Id = :accountId];

        if(dasherOrConsumer.isEmpty() || (String.isBlank(dasherOrConsumer[0].Phone) && String.isBlank(dasherOrConsumer[0].PersonEmail))){
            return false;
        }
        
        String phone = dasherOrConsumer[0].Phone;
        String email = dasherOrConsumer[0].PersonEmail;

        List<August_Data_Question__c> aguestDataQuestionList = [SELECT Id FROM August_Data_Question__c
                                                                WHERE Phone__c = :phone OR Email__c = :email];
        return aguestDataQuestionList.size() > 0;
    }

    /**
     * @author Mahesh Chouhan
     * @date  2022-08
     * @decription Returns a Boolean if User has August Data Question Permission Set.
     * @param   None
     * @return  Boolean - true if User has August Data Question Permission Set othewise false
     */
    public static Boolean checkUserAuthorization(){
        List<PermissionSetAssignment> userPermissions = [SELECT ID
                                                         FROM PermissionSetAssignment
                                                         WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = :AUGUST_DATA_QUESTION_PS];
        return userPermissions.size() > 0;
    }
}