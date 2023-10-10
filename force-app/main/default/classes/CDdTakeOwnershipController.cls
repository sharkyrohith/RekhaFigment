/**
 * 
 * @author: Tia Xuan
 * @date: 2021-02
 * @description Controller for the LDdTakeOwnershipCmp lightning component
 * 
 */
public class CDdTakeOwnershipController {

    @AuraEnabled
    public static void TakeOwnership(String recordId){

        Case cse = new Case();
        cse.Id = recordId;
        cse.OwnerId = UserInfo.getUserId();
        update cse;
        
    }
}