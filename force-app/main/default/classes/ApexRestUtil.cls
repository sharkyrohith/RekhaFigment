public with sharing class ApexRestUtil {
  public static Map<String, Object> reformatSObjectRecord(SObject record) {
    String prefix;
    Map<String, Object> keyToValue, objectAtIndexKM;
    List<Object> listAtIndexK;
    Map<String, Object> reformatedSObject = new Map<String, Object>();
    DataStructures.Queue prefixes = new DataStructures.Queue();
    DataStructures.Queue collectionNodes = new DataStructures.Queue();
    Map<String, Object> sobjectAsMap = record.getPopulatedFieldsAsMap();

    prefixes.enqueue(record.getSObjectType().getDescribe().getLocalName());
    collectionNodes.enqueue(sobjectAsMap);

    List<Object> listObjects = new List<Object>();
    List<String> listObjectPrefixes = new List<String>();
    List<List<Map<String, Object>>> reformatedListObjects = new List<List<Map<String, Object>>>();

    while (!collectionNodes.isEmpty()) {
      keyToValue = (Map<String, Object>) collectionNodes.dequeue();
      prefix = (String) prefixes.dequeue();
      for (String key : keyTovalue.keySet()) {
        // Is Primitive
        if (
          !isCollection(keyToValue.get(key)) &&
          !(keyToValue.get(key) instanceof SObject)
        ) {
          reformatedSObject.put(prefix + '.' + key, keyToValue.get(key));
        } else if (
          (keyToValue.get(key) instanceof SObject) &&
          !(keyToValue.get(key) instanceof List<SObject>)
        ) {
          // is SObject
          prefixes.enqueue(prefix + '.' + key);
          collectionNodes.enqueue(
            ((SObject) keyToValue.get(key)).getPopulatedFieldsAsMap()
          );
        } else if (keyToValue.get(key) instanceof Map<String, Object>) {
          // is Map<String, Object>
          prefixes.enqueue(prefix + '.' + key);
          collectionNodes.enqueue(keyToValue.get(key));
        } else if (keyToValue.get(key) instanceof List<Object>) {
          // is List<SObject>
          listObjectPrefixes.add(prefix + '.' + key);
          listObjects.add(keyToValue.get(key));
          reformatedListObjects.add(new List<Map<String, Object>>());
        }
      }
    }
    for (Integer k = 0; k < listObjects.size(); k++) {
      listAtIndexK = (List<Object>) listObjects[k];
      for (Integer m = 0; m < listAtIndexK.size(); m++) {
        reformatedListObjects[k].add(new Map<String, Object>());
        objectAtIndexKM = ((SObject) listAtIndexK[m]).getPopulatedFieldsAsMap();
        prefixes.enqueue(listObjectPrefixes[k]);
        collectionNodes.enqueue(objectAtIndexKM);

        while (!collectionNodes.isEmpty()) {
          keyToValue = (Map<String, Object>) collectionNodes.dequeue();
          prefix = (String) prefixes.dequeue();
          for (String key : keyTovalue.keySet()) {
            if (
              !isCollection(keyToValue.get(key)) &&
              !(keyToValue.get(key) instanceof SObject)
            ) {
              reformatedListObjects[k][m]
                .put(prefix + '.' + key, keyToValue.get(key));
            } else if ((keyToValue.get(key) instanceof SObject)) {
              prefixes.enqueue(prefix + '.' + key);
              collectionNodes.enqueue(
                ((SObject) keyToValue.get(key)).getPopulatedFieldsAsMap()
              );
            } else if (keyToValue.get(key) instanceof Map<String, Object>) {
              prefixes.enqueue(prefix + '.' + key);
              collectionNodes.enqueue(keyToValue.get(key));
            }
          }
        }
      }
    }

    for (Integer n = 0; n < reformatedListObjects.size(); n++) {
      reformatedSObject.put(listObjectPrefixes[n], reformatedListObjects[n]);
    }
    return reformatedSObject;
  }

  @testVisible
  static Boolean isCollection(Object obj) {
    return (obj instanceof List<Object>) ||
      (obj instanceof Map<String, Object>);
  }
}