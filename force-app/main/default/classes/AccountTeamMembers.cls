public inherited sharing class AccountTeamMembers extends fflib_SObjects implements IAccountTeamMembers {
    public static IAccountTeamMembers newInstance(List<AccountTeamMember> recordList) {
        return (IAccountTeamMembers) Application.Domain.newInstance(recordList);
    }

    public static IAccountTeamMembers newInstance(Set<Id> recordIdSet) {
        return (IAccountTeamMembers) Application.Domain.newInstance(recordIdSet);
    }

    public AccountTeamMembers(List<AccountTeamMember> sObjectList) {
        super(sObjectList, Schema.AccountTeamMember.SObjectType);
    }

    public List<AccountTeamMember> getAccountTeamMembers() {
        return (List<AccountTeamMember>) getRecords();
    }

    /*public List<AccountTeamMember> getAccountTeamMembers(Id accountId) {

    }

    public Map<Id,AccountTeamMember> getAccountTeamMembers(Set<Id> accountIds) {

    }*/

    public class Constructor implements fflib_IDomainConstructor {
        public fflib_SObjects construct(List<Object> objectList) {
            return new AccountTeamMembers ((List<SObject>) objectList);
        }
    }
}