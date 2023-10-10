public interface IAccountTeamMembersSelector extends fflib_ISObjectSelector {
    /**
     * @description This method id for getting object type
     * @param idSet
     * @return List<AccountTeamMember> - List MXP_BoB_Update_ReAccountTeamMemberquest__c
     */
    List<AccountTeamMember> selectById(Set<Id> idSet);

    /**
     * @description This method is used for getting Sobject type Id
     * @param recordIds
     * @return List<AccountTeamMember>
     */
    List<AccountTeamMember> selectById(Set<String> recordIds);

    /**
     * @description This method is used for getting AccountTeamMember by parentId
     * @param accountIds
     * @return List<AccountTeamMember>
     */
    List<AccountTeamMember> selectByAccountId(Set<Id> accountIds);

    /**
     * @description This method is used for getting AccountTeamMember by parentId and roles
     * @param accountIds
     * @param teamMemberRoles
     * @return List<AccountTeamMember>
     */
    List<AccountTeamMember> selectByAccountIdAndRoles(Set<Id> accountIds,Set<String> teamMemberRoles);

    /**
     * @description This method is used for getting AccountTeamMember by userIds and roles
     * @param userIds
     * @param teamMemberRoles
     * @return List<AccountTeamMember>
     */
    List<AccountTeamMember> selectByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles);

    /**
     * @description This method is used for getting AccountTeamMember by userIds or account businees Id and roles
     * @param userIds
     * @param businessIds
     * @param teamMemberRoles
     * @return List<AccountTeamMember>
     */
    List<AccountTeamMember> selectByUserIdOrBusinessIdAndRoles(Set<Id> userIds,Set<Decimal>businessIds,Set<String> teamMemberRoles);

    /**
     * @description This method is used for getting the number of accounts supported by userIds and roles
     * @param userIds
     * @param teamMemberRoles
     * @return Aggregate[]
     */
    Aggregate[] selectCountOfAccountsSupportedGroupedByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles);

     /**
     * @description This method is used for getting Database.QueryLocator 
     * @param userIds
     * @param teamMemberRoles
     * @return Database.QueryLocator
     */
    Database.QueryLocator queryLocatorSelectByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles);

}