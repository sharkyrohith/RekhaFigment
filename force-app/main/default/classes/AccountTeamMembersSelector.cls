public inherited sharing class AccountTeamMembersSelector extends fflib_SObjectSelector implements IAccountTeamMembersSelector {
    /**
    * @description default constructor for the MXP BoB Update Request Selector class
    * @return  - interface of IAccountTeamMembersSelector
    */
    public static IAccountTeamMembersSelector newInstance() {
        return (IAccountTeamMembersSelector) Application.Selector.newInstance(AccountTeamMember.SObjectType);
    }

   /**
    * @description This method is for getting the fields on account object
    * @return List of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            AccountTeamMember.Id,
            AccountTeamMember.AccountId,
            AccountTeamMember.TeamMemberRole,
            AccountTeamMember.UserId
        };
    }

   /**
    * @description This method is used for getting Object type
    * @return Schema.SObjectType
    */
   public Schema.SObjectType getSObjectType() {
       return AccountTeamMember.SObjectType;
   }

   /**
    * @description This method is used for getting Sobject type Id
    * @param idSet
    * @return List<AccountTeamMember>
    */
   public List<AccountTeamMember> selectById(Set<Id> idSet) {
       return (List<AccountTeamMember>) selectSObjectsById(idSet);
   }

   /**
    * @description This method is used for getting Sobject type Id
    * @param recordIds
    * @return List<AccountTeamMember>
    */
   public List<AccountTeamMember> selectById(Set<String> recordIds) {
       fflib_QueryFactory query = newQueryFactory()
            .selectField('User.Name')
            .setCondition('Id IN :recordIds');
       return (List<AccountTeamMember>) Database.query(query.toSOQL());
   }

    /**
    * @description This method is used for getting Sobject type Id
    * @param accountIds
    * @return List<AccountTeamMember>
    */
    public List<AccountTeamMember> selectByAccountId(Set<Id> accountIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('User.Name')
            .setCondition('AccountId IN :accountIds');
        return (List<AccountTeamMember>) Database.query(query.toSOQL());
    }

    /**
    * @description This method is used for getting Sobject type Id
    * @param accountIds
    * @return List<AccountTeamMember>
    */
    public List<AccountTeamMember> selectByAccountIdAndRoles(Set<Id> accountIds,Set<String> teamMemberRoles) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{'User.Name','Account.Case_Routing_Override__c'})
            .setCondition('AccountId IN :accountIds AND TeamMemberRole IN :teamMemberRoles');
        return (List<AccountTeamMember>) Database.query(query.toSOQL());
    }

     /**
    * @description This method is used for getting Sobject type by userId and Roled=
    * @param userIds
    * @param teamMemberRoles
    * @return List<AccountTeamMember>
    */
    public List<AccountTeamMember> selectByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles) {
        fflib_QueryFactory query = newQueryFactory()
            .selectField('User.Name')
            .setCondition('UserId IN :userIds AND TeamMemberRole IN :teamMemberRoles');
        return (List<AccountTeamMember>) Database.query(query.toSOQL());
    }

      /**
    * @description This method is used for getting Sobject type by userId/businessId by Roles
    * @param userIds
    * @param teamMemberRoles
    * @return List<AccountTeamMember>
    */
    public List<AccountTeamMember> selectByUserIdOrBusinessIdAndRoles(Set<Id> userIds,Set<Decimal>businessIds,Set<String> teamMemberRoles) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new Set<String>{'User.Name','Account.Case_Routing_Override__c'})
            .setCondition('(UserId IN :userIds OR Account.Business_ID__c IN : businessIds) AND TeamMemberRole IN :teamMemberRoles');
        return (List<AccountTeamMember>) Database.query(query.toSOQL());
    }

    /**
     * @description This method is used for getting number of merchants supported by the users
     * @param accountsIds
     * @return Aggregate[]
     */
    public Aggregate[] selectCountOfAccountsSupportedGroupedByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles) {
        List<AggregateResult> queryResult = [
                SELECT UserId,User.Name userName,count(Id) cnt
                  FROM AccountTeamMember
                 WHERE UserId in :userIds
                   AND TeamMemberRole IN :teamMemberRoles
              GROUP BY UserId,User.Name];
        return Aggregate.convertResults(queryResult);
    }

     /**
     * @description This method is used for getting Database.QueryLocator 
     * @param userIds
     * @param teamMemberRoles
     * @return Database.QueryLocator
     */
    public Database.QueryLocator queryLocatorSelectByUserIdAndRoles(Set<Id> userIds,Set<String> teamMemberRoles){
        return Database.getQueryLocator(newQueryFactory()
            .selectFields(new Set<String>{'User.Name','Account.Case_Routing_Override__c'})
            .setCondition('UserId IN :userIds AND TeamMemberRole IN :teamMemberRoles').
            toSOQL());
    }
}