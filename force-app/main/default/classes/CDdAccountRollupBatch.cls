/**
 * Created by Jeremy Johnson, Perficient, Inc.
 *
 * BZAP-8356: Backfill #Active Child Accounts to Parent Account
 *
 */
public class CDdAccountRollupBatch implements Database.Batchable<AggregateResult> {
    private static Integer SELECTOR_LIMIT;

    public CDdAccountRollupBatch(Integer selectorLimit) {
        SELECTOR_LIMIT = selectorLimit;
    }

    public Iterable<AggregateResult> start(Database.BatchableContext ctx) {
        List<AggregateResult> activeChildResults = [
                SELECT ParentId, count(Id) children FROM Account
                WHERE
                    IsDeleted = false
                        AND isPersonAccount = false
                        AND ParentId != null
                        AND Currently_Active__c = 'Yes'
                        And Parent.of_Active_Child_Accounts__c = null
                GROUP BY ParentId
                LIMIT :SELECTOR_LIMIT
        ];

        System.debug('CDdAccountRollupBatch, activeChildResults: ' + activeChildResults);
        return activeChildResults;
    }

    public void execute(Database.BatchableContext ctx, List<AggregateResult> activeChildResults) {
        List<Account> accounts = new List<Account>();

        Map<Id, Integer> numberOfActiveChildrenMap = new Map<Id, Integer>();
        for (AggregateResult ar : activeChildResults) {
            numberOfActiveChildrenMap.put((Id) ar.get('ParentId'), (Integer) ar.get('children'));
        }

        for (Id id : numberOfActiveChildrenMap.keySet()) {
            Account account = new Account(
                    Id = id,
                    of_Active_Child_Accounts__c = numberOfActiveChildrenMap.get(id)
            );
            accounts.add(account);
        }

        update accounts;
    }

    public void finish(Database.BatchableContext ctx) {
    }

}