public class InsertPartialUnitOfWorkHelper implements fflib_SObjectUnitOfWork.IDoWork{
	public Database.SaveResult[] results {get; private set;}
    public List<SObject> lstSObjects {get; private set;}
    
    public InsertPartialUnitOfWorkHelper()
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