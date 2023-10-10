@isTest
class JSONUtilityTest {
  static String assertErrorMessage = 'Expected: \n {0} Actual: \n {1}';
  static String jsonStringToBuildSchemaFrom =
    '  {' +
    '    "store_id": "5678",' +
    '    "error": "",' +
    '    "details": {' +
    '      "record_id": "001xxx",' +
    '      "name": "Homer\'s Donut Hut",' +
    '      "legal_business_name": "Homer\'s Donut Hut, LLC",' +
    '      "merchant_supplied_id": "555",' +
    '      "merchant_segment": "Enterprise",' +
    '      "primary_vertical": "Restaurant",' +
    '      "type": "Virtual",' +
    '      "address_id": "abc",' +
    '      "alcohol_addendum_signed": true,' +
    '      "alcohol_eligibility": "Wet",' +
    '      "alcohol_product_eligibility": "Delivery;Pickup;",' +
    '      "menu_ui_type": "Restaurant",' +
    '      "brand": {' +
    '        "record_id": "123xxx",' +
    '        "name": "Homer\'s Donuts",' +
    '        "default_corporate_business_id": "12341",' +
    '        "default_franchise_business_id": "98798"' +
    '      },' +
    '      "franchise_parent": {' +
    '        "record_id": "123xxx",' +
    '        "name": "Homer\'s Donut Hut",' +
    '        "type": "Franchisee"' +
    '      },' +
    '      "parent": {' +
    '        "record_id": "123xxx",' +
    '        "name": "Homer\'s Donut Hut",' +
    '        "type": "Corporate"' +
    '      },' +
    '      "ultimate_parent": {' +
    '        "record_id": "123xxx",' +
    '        "name": "Homer\'s Donut Hut",' +
    '        "type": "Corporate"' +
    '      },' +
    '      "xrefs": [{' +
    '        "record_id": "123xxx",' +
    '        "source": "MDS",' +
    '        "store_id": "5678",' +
    '        "unified_store_id": "2345987",' +
    '        "business_reference": {' +
    '          "business_id": "9876",' +
    '          "business_group_id": "12301",' +
    '          "unified_business_id": "2345666",' +
    '          "business_name": "Homer\'s Enterprises",' +
    '          "default_type": "Franchise"' +
    '        }' +
    '      }, {' +
    '        "record_id": "123xxx",' +
    '        "source": "Drive DB",' +
    '        "store_id": "6543",' +
    '        "business_id": "9898",' +
    '        "business_group_id": "12300",' +
    '        "unified_store_id": "2345987",' +
    '        "business_reference": {' +
    '          "business_id": "9876",' +
    '          "business_group_id": "12300",' +
    '          "unified_business_id": "2345666",' +
    '          "business_name": "Homer\'s Enterprises",' +
    '          "default_type": "Corporate"' +
    '        }' +
    '      }],' +
    '      "contacts": [{' +
    '        "record_id": "123xxx",' +
    '        "first_name": "Homer",' +
    '        "last_name": "Simpson",' +
    '        "email": "homer@example.com",' +
    '        "role": "Store Operator;"' +
    '      }, {' +
    '        "record_id": "123xxx",' +
    '        "first_name": "Marge",' +
    '        "last_name": "Simpson",' +
    '        "email": "marge@example.com",' +
    '        "role": "Decision Maker;Business Admin;"' +
    '      }],' +
    '      "opportunities": [{' +
    '        "record_id": "002xx1",' +
    '        "name": "Homer\'s Donut Hut - Q3 22 - COO",' +
    '        "type": "Existing",' +
    '        "sub_type": "COO",' +
    '        "closed_date": "2023-01-01",' +
    '        "stage": "Contracting"' +
    '      }, {' +
    '        "record_id": "002xx2",' +
    '        "name": "Homer\'s Donut Hut - Q3 22 - Upgrade",' +
    '        "type": "Existing",' +
    '        "sub_type": "COO",' +
    '        "closed_date": "2023-01-01",' +
    '        "stage": "Negotiating"' +
    '      }],' +
    '      "contracts": [{' +
    '        "record_id": "800xxx",' +
    '        "account_name": "",' +
    '        "status": "Activated",' +
    '        "type": "Marketplace",' +
    '        "start_date": "2022-05-18",' +
    '        "master_service_agreement_url": "",' +
    '        "franchise_suppliemental_agreement_url": "",' +
    '        "pricing_summary_url": ""' +
    '      }],' +
    '      "services": [{' +
    '          "product_name": "Marketplace",' +
    '          "package": "",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "0.00",' +
    '          "final_fee": "0.00"' +
    '        },' +
    '        {' +
    '          "product_name": "Delivery",' +
    '          "package": "Marketplace",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "10.00%",' +
    '          "final_fee": "0.00"' +
    '        },' +
    '        {' +
    '          "product_name": "Dashpass",' +
    '          "package": "Marketplace",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "15.00%",' +
    '          "final_fee": "0.00"' +
    '        },' +
    '        {' +
    '          "product_name": "Pickup",' +
    '          "package": "Marketplace",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "6.00%",' +
    '          "final_fee": "0.00"' +
    '        },' +
    '        {' +
    '          "product_name": "Cx Delivery Fee",' +
    '          "package": "Marketplace",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "0.00",' +
    '          "final_fee": "0.00"' +
    '        },' +
    '        {' +
    '          "product_name": "Service Rate",' +
    '          "package": "Marketplace",' +
    '          "status": "active",' +
    '          "mx_agreed_to_product": "Yes",' +
    '          "trial_commission": "0.00",' +
    '          "trial_fee": "0.00",' +
    '          "final_commission__c": "0.00",' +
    '          "final_fee": "0.00"' +
    '        }' +
    '      ]' +
    '    }' +
    '  }';

  static String output1 = '[{"key":"root","dataType":"Map<String, Object>","depth":0,"right":150,"left":1,"index":1,"name":"root"},{"key":"root.store_id","dataType":"Primitive","depth":1,"right":3,"left":2,"index":2,"name":"store_id"},{"key":"root.error","dataType":"Primitive","depth":1,"right":5,"left":4,"index":3,"name":"error"},{"key":"root.details","dataType":"Map<String, Object>","depth":1,"right":149,"left":6,"index":4,"name":"details"},{"key":"root.details.record_id","dataType":"Primitive","depth":2,"right":8,"left":7,"index":5,"name":"record_id"},{"key":"root.details.name","dataType":"Primitive","depth":2,"right":10,"left":9,"index":6,"name":"name"},{"key":"root.details.legal_business_name","dataType":"Primitive","depth":2,"right":12,"left":11,"index":7,"name":"legal_business_name"},{"key":"root.details.merchant_supplied_id","dataType":"Primitive","depth":2,"right":14,"left":13,"index":8,"name":"merchant_supplied_id"},{"key":"root.details.merchant_segment","dataType":"Primitive","depth":2,"right":16,"left":15,"index":9,"name":"merchant_segment"},{"key":"root.details.primary_vertical","dataType":"Primitive","depth":2,"right":18,"left":17,"index":10,"name":"primary_vertical"},{"key":"root.details.type","dataType":"Primitive","depth":2,"right":20,"left":19,"index":11,"name":"type"},{"key":"root.details.address_id","dataType":"Primitive","depth":2,"right":22,"left":21,"index":12,"name":"address_id"},{"key":"root.details.alcohol_addendum_signed","dataType":"Primitive","depth":2,"right":24,"left":23,"index":13,"name":"alcohol_addendum_signed"},{"key":"root.details.alcohol_eligibility","dataType":"Primitive","depth":2,"right":26,"left":25,"index":14,"name":"alcohol_eligibility"},{"key":"root.details.alcohol_product_eligibility","dataType":"Primitive","depth":2,"right":28,"left":27,"index":15,"name":"alcohol_product_eligibility"},{"key":"root.details.menu_ui_type","dataType":"Primitive","depth":2,"right":30,"left":29,"index":16,"name":"menu_ui_type"},{"key":"root.details.brand","dataType":"Map<String, Object>","depth":2,"right":40,"left":31,"index":17,"name":"brand"},{"key":"root.details.brand.record_id","dataType":"Primitive","depth":3,"right":33,"left":32,"index":18,"name":"record_id"},{"key":"root.details.brand.name","dataType":"Primitive","depth":3,"right":35,"left":34,"index":19,"name":"name"},{"key":"root.details.brand.default_corporate_business_id","dataType":"Primitive","depth":3,"right":37,"left":36,"index":20,"name":"default_corporate_business_id"},{"key":"root.details.brand.default_franchise_business_id","dataType":"Primitive","depth":3,"right":39,"left":38,"index":21,"name":"default_franchise_business_id"},{"key":"root.details.franchise_parent","dataType":"Map<String, Object>","depth":2,"right":48,"left":41,"index":22,"name":"franchise_parent"},{"key":"root.details.franchise_parent.record_id","dataType":"Primitive","depth":3,"right":43,"left":42,"index":23,"name":"record_id"},{"key":"root.details.franchise_parent.name","dataType":"Primitive","depth":3,"right":45,"left":44,"index":24,"name":"name"},{"key":"root.details.franchise_parent.type","dataType":"Primitive","depth":3,"right":47,"left":46,"index":25,"name":"type"},{"key":"root.details.parent","dataType":"Map<String, Object>","depth":2,"right":56,"left":49,"index":26,"name":"parent"},{"key":"root.details.parent.record_id","dataType":"Primitive","depth":3,"right":51,"left":50,"index":27,"name":"record_id"},{"key":"root.details.parent.name","dataType":"Primitive","depth":3,"right":53,"left":52,"index":28,"name":"name"},{"key":"root.details.parent.type","dataType":"Primitive","depth":3,"right":55,"left":54,"index":29,"name":"type"},{"key":"root.details.ultimate_parent","dataType":"Map<String, Object>","depth":2,"right":64,"left":57,"index":30,"name":"ultimate_parent"},{"key":"root.details.ultimate_parent.record_id","dataType":"Primitive","depth":3,"right":59,"left":58,"index":31,"name":"record_id"},{"key":"root.details.ultimate_parent.name","dataType":"Primitive","depth":3,"right":61,"left":60,"index":32,"name":"name"},{"key":"root.details.ultimate_parent.type","dataType":"Primitive","depth":3,"right":63,"left":62,"index":33,"name":"type"},{"key":"root.details.xrefs","dataType":"List<Map<String, Object>>","depth":2,"right":86,"left":65,"index":34,"name":"xrefs"},{"key":"root.details.xrefs.record_id","dataType":"Primitive","depth":3,"right":67,"left":66,"index":35,"name":"record_id"},{"key":"root.details.xrefs.source","dataType":"Primitive","depth":3,"right":69,"left":68,"index":36,"name":"source"},{"key":"root.details.xrefs.store_id","dataType":"Primitive","depth":3,"right":71,"left":70,"index":37,"name":"store_id"},{"key":"root.details.xrefs.unified_store_id","dataType":"Primitive","depth":3,"right":73,"left":72,"index":38,"name":"unified_store_id"},{"key":"root.details.xrefs.business_reference","dataType":"Map<String, Object>","depth":3,"right":85,"left":74,"index":39,"name":"business_reference"},{"key":"root.details.xrefs.business_reference.business_id","dataType":"Primitive","depth":4,"right":76,"left":75,"index":40,"name":"business_id"},{"key":"root.details.xrefs.business_reference.business_group_id","dataType":"Primitive","depth":4,"right":78,"left":77,"index":41,"name":"business_group_id"},{"key":"root.details.xrefs.business_reference.unified_business_id","dataType":"Primitive","depth":4,"right":80,"left":79,"index":42,"name":"unified_business_id"},{"key":"root.details.xrefs.business_reference.business_name","dataType":"Primitive","depth":4,"right":82,"left":81,"index":43,"name":"business_name"},{"key":"root.details.xrefs.business_reference.default_type","dataType":"Primitive","depth":4,"right":84,"left":83,"index":44,"name":"default_type"},{"key":"root.details.contacts","dataType":"List<Map<String, Object>>","depth":2,"right":98,"left":87,"index":45,"name":"contacts"},{"key":"root.details.contacts.record_id","dataType":"Primitive","depth":3,"right":89,"left":88,"index":46,"name":"record_id"},{"key":"root.details.contacts.first_name","dataType":"Primitive","depth":3,"right":91,"left":90,"index":47,"name":"first_name"},{"key":"root.details.contacts.last_name","dataType":"Primitive","depth":3,"right":93,"left":92,"index":48,"name":"last_name"},{"key":"root.details.contacts.email","dataType":"Primitive","depth":3,"right":95,"left":94,"index":49,"name":"email"},{"key":"root.details.contacts.role","dataType":"Primitive","depth":3,"right":97,"left":96,"index":50,"name":"role"},{"key":"root.details.opportunities","dataType":"List<Map<String, Object>>","depth":2,"right":112,"left":99,"index":51,"name":"opportunities"},{"key":"root.details.opportunities.record_id","dataType":"Primitive","depth":3,"right":101,"left":100,"index":52,"name":"record_id"},{"key":"root.details.opportunities.name","dataType":"Primitive","depth":3,"right":103,"left":102,"index":53,"name":"name"},{"key":"root.details.opportunities.type","dataType":"Primitive","depth":3,"right":105,"left":104,"index":54,"name":"type"},{"key":"root.details.opportunities.sub_type","dataType":"Primitive","depth":3,"right":107,"left":106,"index":55,"name":"sub_type"},{"key":"root.details.opportunities.closed_date","dataType":"Primitive","depth":3,"right":109,"left":108,"index":56,"name":"closed_date"},{"key":"root.details.opportunities.stage","dataType":"Primitive","depth":3,"right":111,"left":110,"index":57,"name":"stage"},{"key":"root.details.contracts","dataType":"List<Map<String, Object>>","depth":2,"right":130,"left":113,"index":58,"name":"contracts"},{"key":"root.details.contracts.record_id","dataType":"Primitive","depth":3,"right":115,"left":114,"index":59,"name":"record_id"},{"key":"root.details.contracts.account_name","dataType":"Primitive","depth":3,"right":117,"left":116,"index":60,"name":"account_name"},{"key":"root.details.contracts.status","dataType":"Primitive","depth":3,"right":119,"left":118,"index":61,"name":"status"},{"key":"root.details.contracts.type","dataType":"Primitive","depth":3,"right":121,"left":120,"index":62,"name":"type"},{"key":"root.details.contracts.start_date","dataType":"Primitive","depth":3,"right":123,"left":122,"index":63,"name":"start_date"},{"key":"root.details.contracts.master_service_agreement_url","dataType":"Primitive","depth":3,"right":125,"left":124,"index":64,"name":"master_service_agreement_url"},{"key":"root.details.contracts.franchise_suppliemental_agreement_url","dataType":"Primitive","depth":3,"right":127,"left":126,"index":65,"name":"franchise_suppliemental_agreement_url"},{"key":"root.details.contracts.pricing_summary_url","dataType":"Primitive","depth":3,"right":129,"left":128,"index":66,"name":"pricing_summary_url"},{"key":"root.details.services","dataType":"List<Map<String, Object>>","depth":2,"right":148,"left":131,"index":67,"name":"services"},{"key":"root.details.services.product_name","dataType":"Primitive","depth":3,"right":133,"left":132,"index":68,"name":"product_name"},{"key":"root.details.services.package","dataType":"Primitive","depth":3,"right":135,"left":134,"index":69,"name":"package"},{"key":"root.details.services.status","dataType":"Primitive","depth":3,"right":137,"left":136,"index":70,"name":"status"},{"key":"root.details.services.mx_agreed_to_product","dataType":"Primitive","depth":3,"right":139,"left":138,"index":71,"name":"mx_agreed_to_product"},{"key":"root.details.services.trial_commission","dataType":"Primitive","depth":3,"right":141,"left":140,"index":72,"name":"trial_commission"},{"key":"root.details.services.trial_fee","dataType":"Primitive","depth":3,"right":143,"left":142,"index":73,"name":"trial_fee"},{"key":"root.details.services.final_commission__c","dataType":"Primitive","depth":3,"right":145,"left":144,"index":74,"name":"final_commission__c"},{"key":"root.details.services.final_fee","dataType":"Primitive","depth":3,"right":147,"left":146,"index":75,"name":"final_fee"}]';
  static String output2 = '{"store_id":"9820","error":null,"details":{"record_id":"00100001xxxxxxxAAA","name":"Parent 1","legal_business_name":null,"merchant_supplied_id":null,"merchant_segment":null,"primary_vertical":null,"type":null,"address_id":null,"alcohol_addendum_signed":null,"alcohol_eligibility":null,"alcohol_product_eligibility":null,"menu_ui_type":null,"brand":{"record_id":null,"name":null,"default_corporate_business_id":null,"default_franchise_business_id":null},"franchise_parent":{"record_id":null,"name":null,"type":null},"parent":{"record_id":"00100000xxxxxxxAAA","name":"Grand parent","type":null},"ultimate_parent":{"record_id":null,"name":null,"type":null},"xrefs":null,"contacts":null,"opportunities":null,"contracts":null,"services":null}}';
  @isTest
  static void testWhenJSONSchemaThenReturnNestedSet() {
    insert new Api_Contract__c(
      Name = 'TestAPI',
      Contract__c = jsonStringToBuildSchemaFrom,
      External_Id__c = 'TestAPI'
    );
    List<Map<String, Object>> nestedSets = (new JSONUtility.JSON2Relational())
      .convertJSONSchemaFromPayload2NestedSet('TestAPI');
    System.assertEquals(
      output1,
      JSON.serialize(nestedSets),
      String.format(
        assertErrorMessage,
        new List<String>{ output1, JSON.serialize(nestedSets) }
      )
    );
  }

  @isTest
  static void testWhenTargetValuesProvidedThenDynamicallyBuildPayload() {
    insert new Api_Contract__c(
      Name = 'TestAPI',
      Contract__c = jsonStringToBuildSchemaFrom,
      External_Id__c = 'TestAPI'
    );
    JSONUtility.DynamicJSONBuilder builder = new JSONUtility.DynamicJSONBuilder(
      null
    );
    builder.schemaAttributes = new List<Response_Payload_Attribute__c>();
    List<ComparableResponsePayloadAttributeTest> comparableAttributes = new List<ComparableResponsePayloadAttributeTest>();

    for (
      Map<String, Object> entry : (new JSONUtility.JSON2Relational())
        .convertJSONSchemaFromPayload2NestedSet('TestAPI')
    ) {
      comparableAttributes.add(
        new ComparableResponsePayloadAttributeTest(entry)
      );
    }
    comparableAttributes.sort();
    Map<String, Object> attr;
    for (ComparableResponsePayloadAttributeTest entry : comparableAttributes) {
      attr = (Map<String, Object>) entry.obj;
      builder.schemaAttributes.add(
        new Response_Payload_Attribute__c(
          Attribute_Name__c = (String) attr.get('name'),
          Data_Type__c = (String) attr.get('dataType'),
          Index__c = (Decimal) attr.get('index'),
          Left__c = (Decimal) attr.get('left'),
          Right__c = (Decimal) attr.get('right'),
          Depth__c = (Decimal) attr.get('depth'),
          Mapped_Attribute_Name__c = ((Decimal) attr.get('index')) == 2
            ? 'Account.Restaurant_ID__c'
            : (((Decimal) attr.get('index')) == 5
                ? 'Account.Id'
                : (((Decimal) attr.get('index')) == 6
                    ? 'Account.Name'
                    : (((Decimal) attr.get('index')) == 26
                        ? 'Account.Parent'
                        : (((Decimal) attr.get('index')) == 27
                            ? 'Account.Parent.Id'
                            : (((Decimal) attr.get('index')) == 28
                                ? 'Account.Parent.Name'
                                : null))))),
          Name = 'Testing'
        )
      );
    }
    Object reformatedSObject = builder.buildJSONPayloadOnSuccess(
      ApexRestUtil.reformatSObjectRecord(
        new Account(
          Id = '00100001xxxxxxx',
          Name = 'Parent 1',
          Restaurant_ID__c = '9820',
          Parent = new Account(
            Id = '00100000xxxxxxx',
            Name = 'Grand parent',
            Restaurant_ID__c = 'dummy'
          )
        )
      )
    );
    System.assertEquals(
      output2,
      JSON.serialize(reformatedSObject),
      String.format(
        assertErrorMessage,
        new List<String>{ output2, JSON.serialize(reformatedSObject) }
      )
    );
  }
}