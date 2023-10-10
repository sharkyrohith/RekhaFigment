/**
 * cfokle
 */
public with sharing class CDdDMLBulkifier {
  public enum DML {UPDATE_DML}
  private static Map<Schema.SObjectType, Map<Id, SObject>> updateDMLRegistry =
    new Map<Schema.SObjectType, Map<Id, SObject>>();

  public static void enqueueDML(List<SObject> records, DML dmlType){
    if(dmlType == DML.UPDATE_DML){
      enqueueUpdateDML(records);
      return;
    }
  }

  public static void enqueueDML(SObject record, DML dmlType){
    if(dmlType == DML.UPDATE_DML){
      enqueueUpdateDML(record);
      return;
    }
  }

  private static void enqueueUpdateDML(List<SObject> records){
    for(SObject record: records){
      enqueueUpdateDML(record);
    }
  }

  private static void enqueueUpdateDML(SObject record){
    SObject registryRow;
    Map<Id, SObject> temp;
    Schema.SObjectType objType = record.getSObjectType();
    System.debug('sobject type: '+objType);
    Id recordId = (Id) record.get('Id');
    if(!updateDMLRegistry.containsKey(objType)){
      temp = new Map<Id, Sobject>();
      updateDMLRegistry.put(record.getSObjectType(), temp);
    }else {
      temp = updateDMLRegistry.get(objType);
    }
    if(!temp.containsKey(recordId)){
      registryRow = objType.newSObject(recordId);
      temp.put(recordId, registryRow);
    }else{
      registryRow = temp.get(recordId);
    }
    // get updated fields with values from record
    Map<String, Object> updatedFields = record.getPopulatedFieldsAsMap();
    // add updated field values to registry row; log previous and new value of field
    Object oldValue, newValue;
    for(String fieldName : updatedFields.keySet()){
      newValue = updatedFields.get(fieldName);
      // skip child relationship fields
      if(newValue instanceof List<SObject>){
        continue;
      }
      oldValue = registryRow.put(fieldName, newValue);
      System.debug('FIELD_NAME: '+fieldName + ' OLD_VALUE: '+ oldValue + 'NEW_VALUE: '+ newValue);
    }
  }

  public static void processUpdateDMLRegistryRecords(){
    if(updateDMLRegistry ==  null || updateDMLRegistry.isEmpty()){
      return;
    }
    List<SObject> sObjectsToUpdate = new List<SObject>();
    for(Schema.SObjectType objType: updateDMLRegistry.keySet()){
      sObjectsToUpdate.addAll(updateDMLRegistry.get(objType).values());
      updateDMLRegistry.remove(objType);
    }

    if(sObjectsToUpdate.size() > 0) {
      update sObjectsToUpdate;
    }
  }
}