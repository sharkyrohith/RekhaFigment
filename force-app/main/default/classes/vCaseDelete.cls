public class vCaseDelete {

    @InvocableMethod
    public static void vDeleteCase(LIST<Case> cId){
        SET<Id> cIdList = new SET<ID>();
        for(Case c: cId){
            cIdList.add(c.Id);
        }
        vDeleteCaseFuture(cIdList);
    }
    
    @future
    public static void vDeleteCaseFuture(SET<Id> cId){
        LIST<Case> cIdList = [SELECT Id FROM Case WHERE Id IN: cId];
        delete cIdList;
    }
    
}