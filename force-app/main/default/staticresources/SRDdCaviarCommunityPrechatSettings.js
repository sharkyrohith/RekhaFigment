window._snapinsSnippetSettingsFile = (function() {
    var restaurantDetails = [{
                                "label":"First Name",
                                "transcriptFields":[ "Chat_First_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"Last Name",
                                "transcriptFields":[ "Chat_Last_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"Origin",
                                "value": "Chat",
                                "displayToAgent":true
                            },
                            {
                                "label":"Channel",
                                "value": "Caviar Restaurant Community",
                                "transcriptFields":[ "Channel__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"CustomerType",
                                "value": "Merchant",
                                "displayToAgent":false
                            },
                            {
                                "label":"Type",
                                "value": "Caviar Restaurant",
                                "displayToAgent":false
                            },
                            {
                                "label":"Platform",
                                "value": "Caviar",
                                "displayToAgent":false
                            }];
    var dinerDetails =  [{
                            "label":"First Name",
                            "transcriptFields":[ "Chat_First_Name__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":"Last Name",
                            "transcriptFields":[ "Chat_Last_Name__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":"Origin",
                            "value": "Chat",
                            "displayToAgent":true
                        },
                        {
                            "label":"Channel",
                            "value": "Caviar Diner Community",
                            "transcriptFields":[ "Channel__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":"CustomerType",
                            "value": "Consumer",
                            "displayToAgent":false
                        },
                        {
                            "label":"Type",
                            "value": "Caviar Diner",
                            "displayToAgent":false
                        },
                        {
                            "label":"Platform",
                            "value": "Caviar",
                            "displayToAgent":false
                        }];

    var url = window.location.href;
    var createContact = false;
    if (url.includes('restaurants')){
        embedded_svc.snippetSettingsFile.extraPrechatFormDetails = restaurantDetails;
    } else if (url.includes('diners')){
        embedded_svc.snippetSettingsFile.extraPrechatFormDetails = dinerDetails;
    } 
   
    embedded_svc.snippetSettingsFile.extraPrechatInfo = [
        {
            "entityName":"Contact",
            "saveToTranscript": "Contact",
            "entityFieldMaps": [
                {
                    "doCreate":createContact,
                    "doFind":false,
                    "fieldName":"FirstName",
                    "isExactMatch":true,
                    "label":"First Name"
                },
                {
                    "doCreate":createContact,
                    "doFind":false,
                    "fieldName":"LastName",
                    "isExactMatch":true,
                    "label":"Last Name"
                },
                {
                    "doCreate":createContact,
                    "doFind":false,
                    "fieldName":"Phone",
                    "isExactMatch":true,
                    "label":"Phone"
                },
                {
                    "doCreate":createContact,
                    "doFind":true,
                    "fieldName":"Email",
                    "isExactMatch":true,
                    "label":"Email"
                }
            ]
        }, 
        {
            "entityName":"Case",
            "showOnCreate": true,
            "saveToTranscript": "CaseId",
             "entityFieldMaps": [ 
                {
                    "isExactMatch": false,
                    "fieldName": "SuppliedEmail",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Email"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "SuppliedPhone",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Phone"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Origin",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Origin"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Channel__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Channel"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Type",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Type"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Customer_Type__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "CustomerType"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Platform__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Platform"
                }
            ]
        }
    ]
})();