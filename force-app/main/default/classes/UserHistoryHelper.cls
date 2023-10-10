public class UserHistoryHelper {
    
    public static List<String>  fetchUserFieldsToTrack(){
        List<User_History_Custom__c> mcs = User_History_Custom__c.getall().values();
        List<String> fieldsList = new List<String>();
        for(User_History_Custom__c  obj: mcs){
            
            if(obj.Enable_Tracking__c){
                fieldsList.add(obj.Field_Api_Name__c);
            }
        } 
        
        return fieldsList;
    }
    
    public static Void UserHistoryRecords(List<User> newList,Map<Id,User> oldMap){
        
        
        List<String> trackingFields = fetchUserFieldsToTrack();
        List<Sobject> objList = new List<Sobject>();
        if(!trackingFields.isEmpty()){
            List<String> userObjFields = fetchObjectFields('User');
            
            for(User obj:newList){
                User oldUser = oldMap.get(obj.Id);
                
                for(String fldVal :trackingFields){
                    
                    if(userObjFields.contains(fldVal) && obj.get(fldVal) != oldUser.get(fldVal)){
                        // Create a User History Object
                        system.debug('=======>'+ obj.get(fldVal));
                        system.debug('=======>'+string.valueof(obj.get(fldVal)));
                        User_History__c  objUSer = new User_History__c ();
                        objUSer.Name  = fldVal;
                        objUSer.Old_Value__c  = string.valueof(obj.get(fldVal));
                        objUSer.New_Value__c  = string.valueof(oldUser.get(fldVal));
                        objUSer.Changed_By__c = obj.LastModifiedById;
                        objUSer.User__c = obj.Id;
                        objUSer.CreatedById = obj.ID;
                        objUSer.Date__c = system.today();
                        objUSer.UserID__c  =  obj.Id;
                        objList.add(objUSer);	
                        
                        
                    }
                }
            }
            
            if(!objList.isEmpty()){
                insert objList;
            }
            
        }
        
    }
    
    public static List<String> fetchObjectFields(String ObjectName){
        Map <String,Schema.SObjectType> objSchema = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = objSchema.get(ObjectName);
        Schema.DescribeSObjectResult objResult = sobjType.getDescribe();
        Map<String, Schema.SObjectField> mapofObjFields = objResult.fields.getMap();
        List<String> fieldsList = new List<String>();
        for(String fieldName : mapofObjFields.keySet())
        {
            Schema.SObjectField field = mapofObjFields.get(fieldName);
            Schema.DescribeFieldResult fieldSchema = field.getDescribe();
            fieldsList.add(fieldSchema.getName());
        }
        return fieldsList;
        
    }
    
}