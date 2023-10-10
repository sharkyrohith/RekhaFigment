window._snapinsSnippetSettingsFile = (function() {

    var firstNameLbl = "First Name";
    var lastNameLbl = "Last Name";
    var emailLbl = "Email";
    var phoneLbl ="Phone";
    var categoryLbl = "Category";
    var subcategoryLbl = "Subcategory";
    var storeIdLbl = "Store ID";

    var url = new URL(window.location.href);
    var lang = url.searchParams.get("language");
    var language = "English";
    var country = "United States";
    if (lang == "de"){
        language = "German";
        country = "Germany";
        firstNameLbl = "Vorname";
        lastNameLbl = "Nachname";
        emailLbl = "E-Mail";
        phoneLbl = "Telefon";
        categoryLbl = "Kategorie";
        subcategoryLbl = "Unterkategorie";
        storeIdLbl = "Anbieter-ID";
    } else if (lang == "ja"){
        language = "Japanese";
        country = "Japan";
        firstNameLbl = "名";
        lastNameLbl = "姓";
        emailLbl = "メール";
        phoneLbl ="電話";
        categoryLbl = "カテゴリー";
        subcategoryLbl = "サブカテゴリ―";
        storeIdLbl = "加盟店 ID";
    } else if (lang == "fr_CA"){
        language = "French";
        country = "Canada";
        firstNameLbl = "Prénom";
        lastNameLbl = "Nom";
        emailLbl = "Adresse e-mail";
        phoneLbl ="Téléphone";
        categoryLbl = "Catégorie";
        subcategoryLbl = "Sous Catégorie";
    } else if (lang == "es"){
        language = "Spanish";
        country = "United States";
        firstNameLbl = "Nombre";
        lastNameLbl = "Apellidos";
        emailLbl = "Correo electrónico";
        phoneLbl ="Teléfono";
        categoryLbl = "Category";
        subcategoryLbl = "Subcategory";
    } else if (lang == "es_MX"){
        language = "Spanish";
        country = "Mexico";
    } else if (lang == "en_AU"){
        language = "English";
        country = "Australia";
    }else if (lang == "en_NZ"){
        language = "English";
        country = "New Zealand";
    }

    
    
    var consumerDetails =   [{
                                "label":firstNameLbl,
                                "transcriptFields":[ "Chat_First_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":lastNameLbl,
                                "transcriptFields":[ "Chat_Last_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":categoryLbl,
                                "transcriptFields":[ "Issue__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":subcategoryLbl,
                                "transcriptFields":[ "Issue_Subcategory__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":phoneLbl,
                                "transcriptFields":[ "CustomerPhone__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":emailLbl,
                                "transcriptFields":[ "CustomerEmail__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"Origin",
                                "value": "Chat",
                                "displayToAgent":true
                            },
                            {
                                "label":"Channel",
                                "value": "Consumer Community",
                                "transcriptFields":[ "Channel__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"CustomerType",
                                "value": "Consumer",
                                "displayToAgent":true
                            },
                            {
                                "label":"Language",
                                "value": language,
                                "displayToAgent":true
                            },
                            {
                                "label":"Country",
                                "value": country,
                                "displayToAgent":true
                            }];
    var dasherDetails = [{
                            "label":firstNameLbl,
                            "transcriptFields":[ "Chat_First_Name__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":lastNameLbl,
                            "transcriptFields":[ "Chat_Last_Name__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":categoryLbl,
                            "transcriptFields":[ "Issue__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":subcategoryLbl,
                            "transcriptFields":[ "Issue_Subcategory__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":phoneLbl,
                            "transcriptFields":[ "DasherPhoneNo__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":emailLbl,
                            "transcriptFields":[ "DasherEmail__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":"Origin",
                            "value": "Chat",
                            "displayToAgent":true
                        },
                        {
                            "label":"Channel",
                            "value": "Dasher Community",
                            "transcriptFields":[ "Channel__c"],
                            "displayToAgent":true
                        },
                        {
                            "label":"CustomerType",
                            "value": "Dasher",
                            "displayToAgent":false
                        },
                        {
                            "label":"Language",
                            "value": language,
                            "displayToAgent":false
                        },
                        {
                            "label":"Country",
                            "value": country,
                            "displayToAgent":false
                        }];
    var merchantDetails =   [{
                                "label":firstNameLbl,
                                "transcriptFields":[ "Chat_First_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":lastNameLbl,
                                "transcriptFields":[ "Chat_Last_Name__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":categoryLbl,
                                "transcriptFields":[ "Issue__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":subcategoryLbl,
                                "transcriptFields":[ "Issue_Subcategory__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":storeIdLbl,
                                "transcriptFields":[ "MerchantNo__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"Origin",
                                "value": "Chat",
                                "displayToAgent":true
                            },
                            {
                                "label":"Channel",
                                "value": "Merchant Community",
                                "transcriptFields":[ "Channel__c"],
                                "displayToAgent":true
                            },
                            {
                                "label":"CustomerType",
                                "value": "Merchant",
                                "displayToAgent":false
                            },
                            {
                                "label":"Language",
                                "value": language,
                                "displayToAgent":false
                            },
                            {
                                "label":"Country",
                                "value": country,
                                "displayToAgent":false
                            }];
    
    var url = window.location.href;
    var createContact = false;
    if (url.includes('dashers')){
        embedded_svc.snippetSettingsFile.extraPrechatFormDetails = dasherDetails;
    } else if (url.includes('merchants')){
        embedded_svc.snippetSettingsFile.extraPrechatFormDetails = merchantDetails;
        createContact = true;
    } else {
        embedded_svc.snippetSettingsFile.extraPrechatFormDetails = consumerDetails;
    }
    
    /*embedded_svc.snippetSettingsFile.directToButtonRouting = function(prechatFormData) {
        // BZAPSUP-1000 Dx: Add questions to Prechat Form for W2 Dashers
        if (url.includes('dashers')){
            var issueDetailIdx = 0;
            for (var i = 0; i < prechatFormData.length; i++) {
                if (prechatFormData[i].label === "Pre-chat details"){
                    catIdx = i;
                } 
            }
            if(prechatFormData[issueDetailIdx].value === "California Dasher NOT on a Dash"){
                return "5730m0000004DMq";
            }
        }
    }*/


   
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
                    "label":firstNameLbl,
                },
                {
                    "doCreate":createContact,
                    "doFind":false,
                    "fieldName":"LastName",
                    "isExactMatch":true,
                    "label":lastNameLbl,
                },
                {
                    "doCreate":createContact,
                    "doFind":false,
                    "fieldName":"Phone",
                    "isExactMatch":true,
                    "label":phoneLbl,
                },
                {
                    "doCreate":createContact,
                    "doFind":true,
                    "fieldName":"Email",
                    "isExactMatch":true,
                    "label":emailLbl
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
                    "label": emailLbl
                },
                {
                    "isExactMatch": false,
                    "fieldName": "SuppliedPhone",
                    "doCreate": true,
                    "doFind": false,
                    "label": phoneLbl
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
                    "fieldName": "Customer_Type__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "CustomerType"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Language__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Language"
                },
                {
                    "isExactMatch": false,
                    "fieldName": "Country__c",
                    "doCreate": true,
                    "doFind": false,
                    "label": "Country"
                }
            ]
        }
    ]

    embedded_svc.addEventHandler("onChatEndedByChasitor", function(data) {
        var chatKey =  data.liveAgentSessionKey;
        openWindowWithLink("https://help.doordash.com/postchat?chatKey=" + chatKey + "&language=" + lang);
    });
    
    embedded_svc.addEventHandler("onChatEndedByAgent", function(data) {
        var chatKey =  data.liveAgentSessionKey;
        openWindowWithLink("https://help.doordash.com/postchat?chatKey=" + chatKey + "&language=" + lang);
    });

    function redirectToPostchat(url){
        var client_IP;
        var deflt = {country_code: "us"};
        var regionURL = "https://api.doordash.com/v1/country_code_for_ip/";
        var xhttp_GEO = new XMLHttpRequest();
        xhttp_GEO.open('GET', regionURL);
        try {
            xhttp_GEO.send();
            xhttp_GEO.onreadystatechange = function() {
                if(xhttp_GEO.readyState == 4 && xhttp_GEO.status === 200) {
                    var country = JSON.parse(xhttp_GEO.responseText);

                    if (country.subnational_division_code === "fl" ||
                    	country.subnational_division_code === "ga"){
                        openWindowWithLink(url);
                    }
                } 
            }
        } catch(err){
            console.log(err);
        }
    }
    
    function openWindowWithLink(url){
    	var link = document.createElement("a");   
        link.target = "_blank"; 
        link.href = url; 
        document.body.appendChild(link);  
        setTimeout(function() { 
        	link.click();  
            document.body.removeChild(link);  
        }, 500); 
    }

})();
