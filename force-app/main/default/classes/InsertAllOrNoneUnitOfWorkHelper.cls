public inherited sharing class InsertAllOrNoneUnitOfWorkHelper implements fflib_SObjectUnitOfWork.IDoWork{
    public Database.SaveResult[] results {get; private set;}
    public List<SObject> lstSObjects {get; private set;}
    
    public InsertAllOrNoneUnitOfWorkHelper()
    {  
        lstSObjects = new List<SObject>();
    }
    
    public void registerSObjectInsert(SObject record)
    {
        lstSObjects.add(record);
    }
    
    public void doWork()
    {
        results = Database.insert(lstSObjects, true);                
    }
}