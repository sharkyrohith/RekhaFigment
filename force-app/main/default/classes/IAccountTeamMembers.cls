public interface IAccountTeamMembers extends fflib_ISObjects {
    List<AccountTeamMember> getAccountTeamMembers();
    /*List<AccountTeamMember> getAccountTeamMembers(Id accountId);
    Map<Id,AccountTeamMember> getAccountTeamMembers(Set<Id> accountIds);*/
}