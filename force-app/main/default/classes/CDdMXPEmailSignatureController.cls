/**
 * CDdMXPEmailSignatureController
 * @ticket https://doordash.atlassian.net/browse/BASD-15507
 * @author Mahesh Chouhan
 * @date  16 Dec 2021
 * @decription Controller for CDdMXPEmailSignature Visualforce Component
 */
public class CDdMXPEmailSignatureController {

    public string accountId {get;set;}
    private static final String mxpSignature = 'Thanks, <br/>{0} {1}';

    /**
     * @author Mahesh Chouhan
     * @date  16 Dec 2021
     * @decription Retrieve MXP Account Team member info for particular Account
     * @params None
     * @return AccountTeamMember record
     */
    public AccountTeamMember getActm(){
        List<AccountTeamMember> actMembList;
        //If No MXP AccountTeamMemeber exists, email will not be sent
        actMembList = [SELECT Id, User.Signature, User.FirstName,
                       User.Photo_Document_URL__c, User.LastName
                       FROM AccountTeamMember
                       WHERE TeamMemberRole =: CDdSupportConstants.MXP_ROLE_NAME
                       AND AccountId =:accountId];
        return actMembList[0];
    }

    /**
     * @author Mahesh Chouhan
     * @date  16 Dec 2021
     * @decription Get User Signature for Email Template
     * @params None
     * @return String MXP Account Team member user signature
     */
    public String getUserSignature() {
        AccountTeamMember actm = getactm();
        String firstName = actm.User.FirstName != null ? actm.User.FirstName : '';
        String lastNameCharacter = actm.User.LastName.substring(0, 1);
        String userSignature = String.isNotBlank(actm.User.Signature) ?
            actm.User.Signature.replace(CDdCoreConstants.NEW_LINE, CDdCoreConstants.HTML_NEW_LINE) : 
            String.format(mxpSignature, new List<String>{firstName, lastNameCharacter});
        return userSignature;
    }
}