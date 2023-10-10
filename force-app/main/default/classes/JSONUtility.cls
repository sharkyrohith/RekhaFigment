public with sharing class JSONUtility {
  public class DynamicJSONBuilder {
    @testVisible
    public List<Response_Payload_Attribute__c> schemaAttributes;

    public DynamicJSONBuilder(String apiName) {
      schemaAttributes = [
        SELECT
          Id,
          Name,
          Data_Type__c,
          Attribute_Name__c,
          Mapped_Attribute_Name__c,
          Index__c,
          Depth__c,
          Left__c,
          Right__c
        FROM Response_Payload_Attribute__c
        WHERE Name = :apiName
        ORDER BY Depth__c ASC, Index__c ASC
      ];
    }

    public Map<String, Object> buildJSONPayloadOnSuccess(
      Map<String, Object> schemaMappedAttribute2Value
    ) {
      Response_Payload_Attribute__c parentNode, currentNode;
      Map<Decimal, Map<String, Object>> parentIndex2childNodes = new Map<Decimal, Map<String, Object>>{
        schemaAttributes[0].Index__c => new Map<String, Object>()
      };
      DataStructures.Queue parentIndexes = new DataStructures.Queue();
      DataStructures.Queue grandParentIndexes = new DataStructures.Queue();
      parentIndexes.enqueue(0);
      Map<Decimal, List<Map<String, Object>>> parentIndex2ListOfChildNodes = new Map<Decimal, List<Map<String, Object>>>();
      Map<Decimal, List<Map<String, Object>>> parentIndex2DerivedListOfChildNodes = new Map<Decimal, List<Map<String, Object>>>();

      for (Integer k = 1; k < schemaAttributes.size(); k++) {
        currentNode = schemaAttributes[k];
        while (
          !parentIndexes.isEmpty() &&
          !isChild(
            currentNode,
            schemaAttributes[(Integer) parentIndexes.peek()]
          )
        ) {
          grandParentIndexes.enqueue(parentIndexes.dequeue());
        }
        parentNode = schemaAttributes[(Integer) parentIndexes.peek()];
        while (
          !grandParentIndexes.isEmpty() &&
          !isChild(
            parentNode,
            schemaAttributes[(Integer) grandParentIndexes.peek()]
          )
        ) {
          grandParentIndexes.dequeue();
        }
        Object parentNodeReference, parentNodeMappedValues;

        if (parentIndex2childNodes.containsKey(parentNode.Index__c)) {
          parentNodeReference = parentIndex2childNodes.get(parentNode.Index__c);
        } else if (
          parentIndex2ListOfChildNodes.containsKey(parentNode.Index__c)
        ) {
          parentNodeReference = parentIndex2ListOfChildNodes.get(
            parentNode.Index__c
          );
        } else {
          parentNodeReference = parentIndex2DerivedListOfChildNodes.get(
            parentNode.Index__c
          );
        }
        parentNodeMappedValues = (parentNode.Attribute_Name__c == 'root' ||
          parentIndex2childNodes.containsKey(parentNode.Index__c))
          ? schemaMappedAttribute2Value
          : (parentIndex2ListOfChildNodes.containsKey(parentNode.Index__c)
              ? schemaMappedAttribute2Value.get(
                  parentNode.Mapped_Attribute_Name__c
                )
              : schemaMappedAttribute2Value.get(
                  schemaAttributes[(Integer) grandParentIndexes.peek()]
                    .Mapped_Attribute_Name__c
                ));

        if (hasChild(currentNode)) {
          parentIndexes.enqueue(k);
          Object currentNodeMappedValues = (parentIndex2childNodes.containsKey(
              parentNode.Index__c
            ) && currentNode.Data_Type__c == 'Map<String, Object>')
            ? parentNodeMappedValues
            : ((parentIndex2childNodes.containsKey(parentNode.Index__c) &&
                currentNode.Data_Type__c == 'List<Map<String, Object>>')
                ? ((Map<String, Object>) parentNodeMappedValues)
                    .get(currentNode.Mapped_Attribute_Name__c)
                : parentNodeMappedValues);

          if (
            parentIndex2childNodes.containsKey(parentNode.Index__c) &&
            currentNode.Data_Type__c == 'Map<String, Object>'
          ) {
            parentIndex2childNodes.put(
              currentNode.Index__c,
              new Map<String, Object>()
            );
            ((Map<String, Object>) parentNodeReference)
              .put(
                currentNode.Attribute_Name__c,
                parentIndex2childNodes.get(currentNode.Index__c)
              );
            continue;
          }
          if (
            parentIndex2childNodes.containsKey(parentNode.Index__c) &&
            currentNode.Data_Type__c == 'List<Map<String, Object>>'
          ) {
            if (currentNodeMappedValues == null) {
              parentIndex2ListOfChildNodes.put(currentNode.Index__c, null);
              ((Map<String, Object>) parentNodeReference)
                .put(currentNode.Attribute_Name__c, null);
            } else {
              parentIndex2ListOfChildNodes.put(
                currentNode.Index__c,
                new List<Map<String, Object>>()
              );
              ((Map<String, Object>) parentNodeReference)
                .put(
                  currentNode.Attribute_Name__c,
                  parentIndex2ListOfChildNodes.get(currentNode.Index__c)
                );
              for (
                Integer m = 0;
                m <
                ((List<Map<String, Object>>) currentNodeMappedValues).size();
                m++
              ) {
                parentIndex2ListOfChildNodes.get(currentNode.Index__c)
                  .add(new Map<String, Object>());
              }
            }
            continue;
          }
          // parent is either a list or derived list
          if (parentNodeMappedValues == null) {
            parentIndex2DerivedListOfChildNodes.put(currentNode.Index__c, null);
          } else {
            parentIndex2DerivedListOfChildNodes.put(
              currentNode.Index__c,
              new List<Map<String, Object>>()
            );
            for (
              Integer n = 0;
              n < ((List<Map<String, Object>>) parentNodeMappedValues).size();
              n++
            ) {
              parentIndex2DerivedListOfChildNodes.get(currentNode.Index__c)
                .add(new Map<String, Object>());
              ((List<Map<String, Object>>) parentNodeReference)[n]
                .put(
                  currentNode.Attribute_Name__c,
                  parentIndex2DerivedListOfChildNodes.get(currentNode.Index__c)[
                    n
                  ]
                );
            }
          }
          continue;
        }
        // currentNode is primitive
        if (!hasChild(currentNode)) {
          if (parentIndex2childNodes.containsKey(parentNode.Index__c)) {
            ((Map<String, Object>) parentNodeReference)
              .put(
                currentNode.Attribute_Name__c,
                ((Map<String, Object>) parentNodeMappedValues)
                  .get(currentNode.Mapped_Attribute_Name__c)
              );
          } else {
            List<Map<String, Object>> mappedValues = (List<Map<String, Object>>) parentNodeMappedValues;
            List<Map<String, Object>> references = (List<Map<String, Object>>) parentNodeReference;
            if (mappedValues == null) {
              continue;
            }
            for (Integer x = 0; x < mappedValues.size(); x++) {
              references[x]
                .put(
                  currentNode.Attribute_Name__c,
                  mappedValues[x].get(currentNode.Mapped_Attribute_Name__c)
                );
            }
          }
        }
      }
      return parentIndex2childNodes.get(schemaAttributes[0].Index__c);
    }

    Boolean isChild(
      Response_Payload_Attribute__c potentialChild,
      Response_Payload_Attribute__c potentialParent
    ) {
      return potentialChild.Left__c > potentialParent.Left__c &&
        potentialChild.Right__c < potentialParent.Right__c &&
        potentialChild.Depth__c == potentialParent.Depth__c + 1;
    }

    boolean hasChild(Response_Payload_Attribute__c attr) {
      return (attr.left__c + 1 < attr.right__c);
    }

    boolean hasSibling(
      Response_Payload_Attribute__c attr,
      Response_Payload_Attribute__c parentAttr
    ) {
      return attr.right__c + 1 < parentAttr.right__c;
    }
  }

  public class JSON2Relational {
    public List<Map<String, Object>> convertJSONSchemaFromPayload2NestedSet(
      String apiName
    ) {
      return convertJSONSchemaFromPayload2NestedSet(apiName, false);
    }

    public List<Map<String, Object>> convertJSONSchemaFromPayload2NestedSet(
      String apiName,
      boolean saveToResponsePayloadAttributeObject
    ) {
      if (saveToResponsePayloadAttributeObject && String.isBlank(apiName)) {
        throw new JSON2RelationalException(
          'apiName is required when trying to save records.'
        );
      }
      String jsonPayload = [
        SELECT Id, Contract__c
        FROM API_Contract__c
        WHERE External_Id__c = :apiName
      ][0]
      .Contract__c;
      List<Map<String, Object>> nestedSetsSchema = new List<Map<String, Object>>{
        new Map<String, Object>{
          'name' => 'root',
          'index' => 1,
          'left' => 1,
          'right' => null,
          'depth' => 0,
          'dataType' => 'Map<String, Object>',
          'key' => 'root'
        }
      };
      recursiveSchemaConversion(
        nestedSetsSchema,
        (Map<String, Object>) JSON.deserializeUntyped(jsonPayload),
        1,
        'root'
      );
      if (saveToResponsePayloadAttributeObject) {
        saveNestedSetsToResponsePayloadAttributeObject(
          nestedSetsSchema,
          apiName
        );
      }
      return nestedSetsSchema;
    }

    void recursiveSchemaConversion(
      List<Map<String, Object>> convertedSchema,
      Map<String, Object> payLoad,
      Integer depth,
      String parentKey
    ) {
      Map<String, Object> lastAttribute = convertedSchema[
        convertedSchema.size() - 1
      ];
      Map<String, Object> parentAttribute = convertedSchema[
        convertedSchema.size() - 1
      ];
      for (String str : payLoad.keySet()) {
        convertedSchema.add(
          new Map<String, Object>{
            'name' => str,
            'index' => convertedSchema.size() + 1,
            'left' => (lastAttribute.get('right') != null)
              ? ((Integer) lastAttribute.get('right')) + 1
              : ((Integer) lastAttribute.get('left')) + 1,
            'right' => isPrimitive(payLoad.get(str))
              ? (lastAttribute.get('right') != null)
                  ? ((Integer) lastAttribute.get('right')) + 2
                  : ((Integer) lastAttribute.get('left')) + 2
              : null,
            'depth' => depth,
            'dataType' => 'Primitive',
            'key' => parentKey +
            '.' +
            str
          }
        );
        lastAttribute = convertedSchema[convertedSchema.size() - 1];
        if (payLoad.get(str) instanceof Map<String, Object>) {
          Map<String, Object> childNodes = (Map<String, Object>) payLoad.get(
            str
          );
          recursiveSchemaConversion(
            convertedSchema,
            childNodes,
            depth + 1,
            parentKey + '.' + str
          );
          lastAttribute.put('dataType', 'Map<String, Object>');
        } else if (payLoad.get(str) instanceof List<Object>) {
          Map<String, Object> childNodes = (Map<String, Object>) ((List<Object>) payLoad.get(
            str
          ))[0];
          recursiveSchemaConversion(
            convertedSchema,
            childNodes,
            depth + 1,
            parentKey + '.' + str
          );
          lastAttribute.put('dataType', 'List<Map<String, Object>>');
        }
      }
      parentAttribute.put('right', (Integer) lastAttribute.get('right') + 1);
    }

    boolean isPrimitive(Object obj) {
      return (!(obj instanceof Map<String, Object>)) &&
        (!(obj instanceof List<Object>));
    }

    void saveNestedSetsToResponsePayloadAttributeObject(
      List<Map<String, Object>> convertedSchema,
      String apiName
    ) {
      List<Response_Payload_Attribute__c> attrsToSave = new List<Response_Payload_Attribute__c>();
      for (Map<String, Object> attr : convertedSchema) {
        attrsToSave.add(
          new Response_Payload_Attribute__c(
            Attribute_Name__c = (String) attr.get('name'),
            Data_Type__c = (String) attr.get('dataType'),
            Index__c = (Decimal) attr.get('index'),
            Left__c = (Decimal) attr.get('left'),
            Right__c = (Decimal) attr.get('right'),
            Depth__c = (Decimal) attr.get('depth'),
            Name = apiName,
            Key__c = (String) attr.get('key'),
            External_Id__c = apiName + (String) attr.get('key')
          )
        );
      }
      insert attrsToSave;
    }
  }

  public class JSON2RelationalException extends Exception {
  }
}