/**
 *
 * @author: Tia Xuan
 * @date: 2020-05
 * @description Community web case creation controller for LDdCommunityWebCaseCmp
 *
 */
public class CDdCommunityWebCaseController {
    public static final String MERCHANT_COMMUNITY = 'merchants';
    public static final Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    @AuraEnabled
    public static CommunityWebCaseWrapper initCommunityWebCase(String community, String language, string page){
        CommunityWebCaseWrapper retVal = new CommunityWebCaseWrapper();
        retVal = getPicklists(community, language, page, retVal);
        Map<String, Schema.SObjectType> schemaMap = SOBJECT_TYPES;
        Schema.SObjectType leadSchema = schemaMap.get('Case');
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        retVal.nameLabel = fieldMap.get('Full_Name__c').getDescribe().getLabel();
        retVal.emailLabel = fieldMap.get('SuppliedEmail').getDescribe().getLabel();
        retVal.phoneLabel = fieldMap.get('SuppliedPhone').getDescribe().getLabel();
        if (page == 'contactsupport'){
            if (community == 'consumers'){
                retVal.categoryLabel = fieldMap.get('comm_dependent_cx_Category__c').getDescribe().getLabel();
                retVal.subcategoryLabel = fieldMap.get('communities_cx_Subcategory__c').getDescribe().getLabel();
                retVal = getCatOpts(retVal,
                                    'Case',
                                    'communities_cx_Subcategory__c');
            } else if (community == 'dashers'){
                retVal.categoryLabel = fieldMap.get('communities_dependent_dx_Category__c').getDescribe().getLabel();
                retVal.subcategoryLabel = fieldMap.get('communities_dx_Subcategory__c').getDescribe().getLabel();
                retVal = getCatOpts(retVal,
                                    'Case',
                                    'communities_dependent_dx_Category__c');
                // New for Dasher Project W
                retVal.isCaliforniaDasherLabel = Label.DdCommunity_Dasher_Q_California;
                retVal.isCaliforniaDasherOptions = CDdCommunityHelper.initPicklistYesNo();
                retVal.isOnDashLabel = Label.DdCommunity_Dasher_Q_Dash;
                retVal.isOnDashOptions = CDdCommunityHelper.initPicklistYesNo();
                // End for Dasher Project W
            } else if (community == 'merchants' || community == 'restaurants'){
                retVal.restaurantNameLabel = fieldMap.get('comm_Restaurant_Name__c').getDescribe().getLabel();
                retVal.storeIdLabel = fieldMap.get('Store_ID__c').getDescribe().getLabel();
                retVal.caviarServiceRegionLabel = fieldMap.get('Caviar_Service_Region__c').getDescribe().getLabel();
                retVal.csrOptions = CDdCommunityHelper.getCommunityPicklistValues('Case', 'Caviar_Service_Region__c');
                retVal.restaurantAddressLabel = fieldMap.get('comm_Restaurant_Address__c').getDescribe().getLabel();
                retVal.categoryLabel = fieldMap.get('communities_dependent_mx_Category__c').getDescribe().getLabel();
                retVal.subcategoryLabel = fieldMap.get('communities_mx_Subcategory__c').getDescribe().getLabel();
                retVal = getCatOpts(retVal,
                                    'Case',
                                    'communities_dependent_mx_Category__c');
            } else if (community == 'diners'){
                retVal.categoryLabel = fieldMap.get('Caviar_Diner_Category__c').getDescribe().getLabel();
                retVal.subcategoryLabel = fieldMap.get('Subcategory_Caviar_Diner__c').getDescribe().getLabel();
                retVal = getCatOpts(retVal,
                                    'Case',
                                    'Caviar_Diner_Category__c');
            } else if (community == 'couriers'){
                retVal.caviarServiceRegionLabel = fieldMap.get('Caviar_Service_Region__c').getDescribe().getLabel();
                retVal.csrOptions = CDdCommunityHelper.getCommunityPicklistValues(   'Case',
                                                                            'Caviar_Service_Region__c');
                retVal.issueTopicLabel = fieldMap.get('Caviar_courier_category__c').getDescribe().getLabel();
                retVal.itOptions = CDdCommunityHelper.getCommunityPicklistValues(   'Case',
                                                                            'Caviar_courier_category__c');
            } else if (community == 'work'){
                retVal.companyLabel = fieldMap.get('SuppliedCompany').getDescribe().getLabel();
                retVal.issueCategoryLabel = fieldMap.get('Caviar_CFC_Topic__c').getDescribe().getLabel();
                retVal.icOptions = CDdCommunityHelper.getCommunityPicklistValues('Case',
                                                                        'Caviar_CFC_Topic__c');
            }
        } else if (page == 'healthandsafety'){
            retVal.typeOfIncidentLabel = fieldMap.get('Type_of_Issue__c').getDescribe().getLabel();
            retVal.toiOptions = CDdCommunityHelper.getCommunityPicklistValues(   'Case',
                                                                        'Type_of_Issue__c');
        } else if (page == 'emailcfcsupport') {
            retVal.restaurantNameLabel = fieldMap.get('comm_Restaurant_Name__c').getDescribe().getLabel();
            retVal.restaurantAddressLabel = fieldMap.get('comm_Restaurant_Address__c').getDescribe().getLabel();
            retVal.caviarServiceRegionLabel = fieldMap.get('Caviar_Service_Region__c').getDescribe().getLabel();
            retVal.csrOptions = CDdCommunityHelper.getCommunityPicklistValues(   'Case',
                                                                        'Caviar_Service_Region__c');
            retVal.issueCategoryLabel = fieldMap.get('CFC_RS_Issue_Category__c').getDescribe().getLabel();
            retVal.icOptions = CDdCommunityHelper.getCommunityPicklistValues('Case',
                                                                    'CFC_RS_Issue_Category__c');
        } else if (page == 'emailliveopssupport') {
            retVal.caviarServiceRegionLabel = fieldMap.get('Caviar_Service_Region__c').getDescribe().getLabel();
            retVal.csrOptions = CDdCommunityHelper.getCommunityPicklistValues(   'Case',
                                                                        'Caviar_Service_Region__c');
            retVal.issueCategoryLabel = fieldMap.get('CFC_LiveOps_Topic__c').getDescribe().getLabel();
            retVal.icOptions = CDdCommunityHelper.getCommunityPicklistValues('Case',
                                                                    'CFC_LiveOps_Topic__c');
        }
        retVal.descriptionLabel = fieldMap.get('Description').getDescribe().getLabel();
        return retVal;
    }

    @AuraEnabled
    public static String saveCommunityWebCase( String community, String language, String wrpString, String page){
        CommunityWebCaseWrapper wrp = (CommunityWebCaseWrapper) JSON.deserialize(wrpString, CommunityWebCaseWrapper.class);

        Boolean isCaviar = ((community == 'diners')
                            || (community == 'couriers')
                            || (community == 'work') || wrp.category == 'Menu Change');
        String rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support').getRecordTypeId();
        if (isCaviar){
            rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Caviar Support').getRecordTypeId();
        }
        Map<String, String> catValues = new Map<String, String>();
        Map<String, String> subcatValues = new Map<String, String>();
        String caseBody = ' {';
        caseBody += '"RecordTypeId":"' + rtId + '",';
        caseBody += '"Full_Name__c":"' + wrp.name + '",';
        caseBody += '"SuppliedEmail":"' + wrp.email + '",';
        caseBody += '"SuppliedPhone":"' + wrp.phone + '",';
        if (page == 'contactsupport'){
            if (community == 'consumers'){
                caseBody += '"Communities_Source__c":"Consumer",';
                caseBody += '"Customer_Type__c":"Consumer",';
                caseBody += '"Channel__c":"Consumer Community",';
                caseBody += '"Community_Form__c":"Consumer",';
                caseBody += '"comm_dependent_cx_Category__c":"' + wrp.category + '",';
                caseBody += '"communities_cx_Subcategory__c":"'  + wrp.subcategory + '",';
            } else if (community == 'dashers'){
                caseBody += '"Communities_Source__c":"Dasher",';
                caseBody += '"Customer_Type__c":"Dasher",';
                caseBody += '"Channel__c":"Dasher Community",';
                caseBody += '"Community_Form__c":"Dasher",';
                caseBody += '"communities_dependent_dx_Category__c":"' + wrp.category + '",';
                caseBody += '"communities_dx_Subcategory__c":"'  + wrp.subcategory + '",';
                // New for Dasher Project W
                if ((wrp.isDasherW) && (wrp.isCaliforniaDasher != '') && (wrp.isOnDash != '')) {
                    caseBody += '"Chat_Issue_Details__c":"';
                    // caseBody += wrp.isCaliforniaDasherLabel + ' ' + wrp.isCaliforniaDasher + ' | ';
                    // caseBody += wrp.isOnDashLabel + ' ' + wrp.isOnDash;
                    if (wrp.isCaliforniaDasher == Label.DdCommunity_Yes) {
                        caseBody += 'California Dasher';
                        caseBody += (wrp.isOnDash == Label.DdCommunity_Yes) ? ' ' : ' NOT ';
                        caseBody += 'on a Dash';
                    }
                    else {
                        caseBody += 'Not a California Dasher';
                    }
                    caseBody += '",';
                }
                // End for Dasher Project W
            } else if ((community == 'merchants' || community == 'restaurants') && !isCaviar){
                caseBody += '"Communities_Source__c":"Merchant",';
                caseBody += '"Customer_Type__c":"Merchant",';
                caseBody += '"Channel__c":"Merchant Community",';
                caseBody += '"comm_Restaurant_Name__c":"' + wrp.restaurantName + '",';
                caseBody += '"Store_ID__c":"' + wrp.storeId + '",';
                caseBody += '"comm_Restaurant_Address__c":"' + escapeTextarea(wrp.restaurantAddress) + '",';
                caseBody += '"Community_Form__c":"Merchant",';
                caseBody += '"communities_dependent_mx_Category__c":"' + wrp.category + '",';
                caseBody += '"communities_mx_Subcategory__c":"' + wrp.subcategory + '",';
                if(community == 'restaurants'){
                    caseBody += '"Platform__c":"Caviar",';
                }
            }  else if (community == 'diners'){
                caseBody += '"Communities_Source__c":"Diners",';
                caseBody += '"Customer_Type__c":"Consumer",';
                caseBody += '"Channel__c":"Caviar Diner Community",';
                caseBody += '"Platform__c":"Caviar",';
                caseBody += '"Type":"Caviar Diner",';
                caseBody += '"Community_Form__c":"Diners - Caviar",';
                caseBody += '"Caviar_Diner_Category__c":"' + wrp.category + '",';
                caseBody += '"Subcategory_Caviar_Diner__c":"'  + wrp.subcategory + '",';
                // BZAPSUP-214 Update Caviar Forms with new Web Form
                // Caviar Diner Support - Route Inbound Cases
                // https://figment.my.salesforce.com/01Q2L0000001tWH
                caseBody += '"Subject":"Inbound Diner Email - '  + wrp.category + '",';
                caseBody += '"OwnerId":"'  + Label.CavCommunity_Diner_Support_Queue_Email + '",';
            } else if (community == 'couriers'){
                caseBody += '"Communities_Source__c":"Courier",';
                caseBody += '"Customer_Type__c":"Dasher",';
                caseBody += '"Channel__c":"Caviar Courier Community",';
                caseBody += '"Platform__c":"Caviar",';
                caseBody += '"Type":"Caviar Courier",';
                caseBody += '"Community_Form__c":"Courier - Caviar",';
                caseBody += '"Caviar_Service_Region__c":"' + wrp.caviarServiceRegion + '",';
                caseBody += '"Caviar_courier_category__c":"'  + wrp.issueTopic + '",';
                // BZAPSUP-214 Update Caviar Forms with new Web Form
                // Caviar Courier Support - Route Inbound Cases
                // https://figment.my.salesforce.com/01Q2L0000001tWF
                caseBody += '"Subject":"'  + wrp.issueTopic + ' - ' + wrp.name + '",';
                caseBody += '"OwnerId":"'  + Label.CavCommunity_Courier_Support_Queue + '",';
                Set<String> highPriorityIssueTopics = new Set<String>(
                    Label.CavCommunity_High_Priority_Issue_Topics.split(';'));

                // BZAPSUP-214 Update Caviar Forms with new Web Form
                // Caviar Courier Support - Tag High-Touch Cases
                // https://figment.my.salesforce.com/01Q2L000000Djoa
                if (highPriorityIssueTopics.contains(wrp.issueTopic)){
                    caseBody += '"Priority":"High",';
                }
            } else if (community == 'restaurants' && isCaviar){
                caseBody += '"Communities_Source__c":"Merchant",';
                caseBody += '"Customer_Type__c":"Merchant",';
                caseBody += '"Channel__c":"Caviar Restaurant Community",';
                caseBody += '"Platform__c":"Caviar",';
                caseBody += '"comm_Restaurant_Name__c":"' + wrp.restaurantName + '",';
                caseBody += '"comm_Restaurant_Address__c":"' + escapeTextarea(wrp.restaurantAddress) + '",';
                caseBody += '"Community_Form__c":"Merchant - Caviar",';
                caseBody += '"Caviar_Service_Region__c":"' + wrp.caviarServiceRegion + '",';
                caseBody += '"Caviar_Topic__c":"' + wrp.category + '",';
                caseBody += '"Caviar_Type_of_Request__c":"' + wrp.subcategory + '",';
                caseBody += '"OwnerId":"'  + Label.CavCommunity_Menu_Team + '",';
                caseBody += '"Subject":"'  + wrp.category + ' - ' + wrp.restaurantName + ' - ' + wrp.name + '",';
                caseBody += '"Type":"Caviar Content",';
            } else if (community == 'work'){
                caseBody += '"Communities_Source__c":"Companies",';
                caseBody += '"Customer_Type__c":"Companies",';
                caseBody += '"Channel__c":"Caviar for Companies Community",';
                caseBody += '"Platform__c":"Caviar",';
                caseBody += '"Type":"Caviar Corporate",';
                caseBody += '"Community_Form__c":"Companies - Caviar",';
                caseBody += '"SuppliedCompany":"' + wrp.company + '",';
                caseBody += '"Caviar_CFC_Topic__c":"' + wrp.issueCategory + '",';
                // BZAPSUP-214 Update Caviar Forms with new Web Form
                // CFC Support - Route Inbound Cases to CFC Menu Makers Team
                // https://figment.my.salesforce.com/01Q2L000000DjnI
                Set<String> issueCats = new Set<String>(
                    Label.CavCommunity_CFC_Issue_Categories_Menu_Makers.split(';'));
                if (issueCats.contains(wrp.issueCategory)){
                    caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_Menu_Maker_Team + '",';
                    caseBody += '"Subject":"' + wrp.issueCategory + ' - ' + wrp.company + ' - ' + wrp.name + '",';
                }
                // BZAPSUP-214 Update Caviar Forms with new Web Form
                // CFC Support - Route Inbound Cases to CFC Support Team
                // https://figment.my.salesforce.com/01Q2L000000DjRX
                if (!issueCats.contains(wrp.issueCategory)){
                    caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_Support + '",';
                    caseBody += '"Subject":"' + wrp.issueCategory + ' - ' + wrp.company + ' - ' + wrp.name + '",';
                }
            }
        } else if (page == 'healthandsafety'){
            if (community == 'consumers'){
                caseBody += '"Communities_Source__c":"Consumer",';
                caseBody += '"Customer_Type__c":"Consumer",';
                caseBody += '"Channel__c":"Consumer Community",';
                caseBody += '"Community_Form__c":"Consumer Health Safety",';
                caseBody += '"comm_dependent_cx_Category__c":"Health, Safety or Legal Concern (including allergies or allergic reactions)",';
            } else if (community == 'dashers'){
                caseBody += '"Communities_Source__c":"Dasher",';
                caseBody += '"Customer_Type__c":"Dasher",';
                caseBody += '"Channel__c":"Dasher Community",';
                caseBody += '"Community_Form__c":"Dasher Health Safety",';
                caseBody += '"communities_dependent_dx_Category__c":"Health, Safety or Legal Concern",';
            } else if (community == 'merchants'){
                caseBody += '"Communities_Source__c":"Merchant",';
                caseBody += '"Customer_Type__c":"Merchant",';
                caseBody += '"Channel__c":"Merchant Community",';
                caseBody += '"Community_Form__c":"Merchant Health Safety",';
                caseBody += '"communities_dependent_mx_Category__c":"Health, Safety or Legal Concern",';
            }
            caseBody += '"Type_of_Issue__c":"' + wrp.typeOfIncident + '",';
        } else if (page == 'emailcfcsupport'){
            caseBody += '"Communities_Source__c":"Restaurant",';
            caseBody += '"Customer_Type__c":"Merchant",';
            caseBody += '"Channel__c":"Caviar Restaurant Community",';
            caseBody += '"Platform__c":"Caviar",';
            caseBody += '"Type":"Merchant Catering",';
            caseBody += '"Community_Form__c":"CFC Merchant - Caviar",';
            caseBody += '"comm_Restaurant_Name__c":"' + wrp.restaurantName + '",';
            caseBody += '"comm_Restaurant_Address__c":"' + escapeTextarea(wrp.restaurantAddress) + '",';
            caseBody += '"Caviar_Service_Region__c":"' + wrp.caviarServiceRegion + '",';
            //caseBody += '"Caviar_CFC_Topic__c":"' + wrp.issueCategory + '",';
            caseBody += '"CFC_RS_Issue_Category__c":"' + wrp.issueCategory + '",';
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC RS Support - Route to CFC Menu Maker Team
            // https://figment.my.salesforce.com/01Q2L000000Djnc
            if (wrp.issueCategory == 'Menu Update'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_Menu_Maker_Team + '",';
                caseBody += '"Subject":"' + wrp.issueCategory + ' - ' + wrp.restaurantName + ' - ' + wrp.name + '",';
            }
        } else if (page == 'emailliveopssupport'){
            caseBody += '"Channel__c":"Caviar for Companies Community",';
            caseBody += '"Communities_Source__c":"Companies",';
            caseBody += '"Community_Form__c":"CFC Live Ops - Caviar",';
            caseBody += '"Customer_Type__c":"Courier",';
            caseBody += '"Platform__c":"Caviar",';
            caseBody += '"Type":"Caviar Corporate",';
            caseBody += '"Caviar_Service_Region__c":"' + wrp.caviarServiceRegion + '",';
            //caseBody += '"Caviar_CFC_Topic__c":"' + wrp.issueCategory + '",';
            caseBody += '"CFC_LiveOps_Topic__c":"' + wrp.issueCategory + '",';
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Live Ops Support - Route to Live Ops Team
            // https://figment.my.salesforce.com/01Q2L000000Djnh
            Set<String> cats = new Set<String>(
                Label.CavCommunity_LiveOps_Categories.split(';'));
            Set<String> regions = new Set<String>(
                Label.CavCommunity_LiveOps_Regions.split(';'));
            boolean subjectFilled = false;
            if (!cats.contains(wrp.issueCategory)
                || (cats.contains(wrp.issueCategory)
                 && regions.contains(wrp.caviarServiceRegion))){
                if (!cats.contains(wrp.issueCategory)){
                    caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_Live_Ops + '",';
                }
                caseBody += '"Subject":"' + wrp.issueCategory + ' - ' + wrp.Name + '",';
                subjectFilled = true;
            }

            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Live Ops Support - Update Subject for Hub Teams
            // https://figment.my.salesforce.com/01Q2L000000Djnm
            if (cats.contains(wrp.issueCategory)
                && !subjectFilled){
                caseBody += '"Subject":"' + wrp.issueCategory + ' - ' + wrp.Name + '",';
            }

            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Onboarding - Route to Hub Team (LA)
            // https://figment.my.salesforce.com/01Q2L000000oSLf
            if (cats.contains(wrp.issueCategory)
                && wrp.caviarServiceRegion == 'Los Angeles'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_LA_Hub_Team + '",';
            }
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Onboarding - Route to Hub Team (NYC)
            // https://figment.my.salesforce.com/01Q2L000000oSLg
            if (cats.contains(wrp.issueCategory)
                && wrp.caviarServiceRegion == 'New York City'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_NYC_Hub_Team + '",';
            }
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Onboarding - Route to Hub Team (Palo Alto)
            // https://figment.my.salesforce.com/01Q2L000000oSLh
            if (cats.contains(wrp.issueCategory)
                && wrp.caviarServiceRegion == 'Palo Alto'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_PaloAlto_Hub_Team + '",';
            }
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Onboarding - Route to Hub Team (SF)
            // https://figment.my.salesforce.com/01Q2L000000oSLi
            if (cats.contains(wrp.issueCategory)
                && wrp.caviarServiceRegion == 'San Francisco'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_SF_Hub_Team + '",';
            }
            // BZAPSUP-214 Update Caviar Forms with new Web Form
            // CFC Onboarding - Route to Hub Team (SJ)
            // https://figment.my.salesforce.com/01Q2L000000oSLj
            if (cats.contains(wrp.issueCategory)
                && wrp.caviarServiceRegion == 'San Jose'){
                caseBody += '"OwnerId":"' + Label.CavCommunity_CFC_SJ_Hub_Team + '",';
            }
        }

        Country_Mapping__c cm = CDdSupportHelper.getCountryMapping(language);
        caseBody += '"Language__c":"' + cm.Language__c + '",';
        caseBody += '"Country__c":"' + cm.Country__c + '",';
        caseBody += '"Language":"' + language +'",';
        caseBody += '"Origin":"Web",';
        caseBody += '"Status":"New",';
        if (community == MERCHANT_COMMUNITY) {
            //BZAPSUP-1473 Add more context to description for cases coming from merchant community
            String concatDescription =  CDdCoreConstants.NEW_LINE + wrp.category              +
                                        ' - '                     + wrp.subcategory           +
                                        CDdCoreConstants.NEW_LINE + CDdCoreConstants.NEW_LINE +
                                        'Restaurant Name: '       + wrp.restaurantName        +
                                        CDdCoreConstants.NEW_LINE + 'Store ID: '              +
                                        wrp.storeId               + CDdCoreConstants.NEW_LINE +
                                        'Restaurant Address: '    + escapeTextarea(wrp.restaurantAddress) +
                                        CDdCoreConstants.NEW_LINE + 'Contact Name: '          +
                                        wrp.name                  + CDdCoreConstants.NEW_LINE +
                                        'Contact Email: '         + wrp.email                 +
                                        CDdCoreConstants.NEW_LINE + 'Contact Phone: '         +
                                        wrp.phone                 + CDdCoreConstants.NEW_LINE +
                                        CDdCoreConstants.NEW_LINE + wrp.description;

            caseBody += '"Description":"' + escapeTextarea(concatDescription) + '"';
          } else {
            caseBody += '"Description":"' + escapeTextarea(wrp.description) + '"';
          }
        caseBody += '}';
        return insertCaseAPI(caseBody);
    }

    @AuraEnabled
    public static Boolean verifyRecaptcha(String recaptchaResponse, Boolean isCaviar){
        String commName = 'DoorDash';
        if (isCaviar){
            commName = 'Caviar';
        }

        Recaptcha_Setting__mdt setting =[select Secret_Key__c,
                                                Verify_URL__c,
                                                Minimum_Score__c
                                        from Recaptcha_Setting__mdt
                                        where MasterLabel =: commName];
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(setting.Verify_URL__c);
        request.setMethod('POST');
        request.setBody('secret=' + setting.Secret_Key__c + '&response=' + recaptchaResponse);
        HttpResponse response = http.send(request);

        if (response.getStatusCode() == 200) {
            System.debug(response.getBody());
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if (result.containsKey('success') && result.get('success') == true) {
                Double minScore = (Double) result.get('score');
                if (minScore != null && minScore >= setting.Minimum_Score__c){
                    return true;
                } else  {
                    return false;
                }
            } else {
                return false;
            }
        }
        return false;
    }

    private static String insertCaseAPI(String caseBody){
        String restURL = 'callout:SalesforceNamedCred/services/data/v48.0/sobjects/Case';

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(restURL);
        req.setBody(caseBody);
        req.setTimeout(60000);
        HttpResponse resp = http.send(req);
        return resp.getBody();
    }

    private static CommunityWebCaseWrapper getPicklists(String community, String language, string page, CommunityWebCaseWrapper wrp){
        List<Community_Webform_Picklist__c> picklists = [select Community__c,
                                                                Language__c,
                                                                Page__c,
                                                                Field_Name__c,
                                                                Field_Label__c,
                                                                Field_Value__c,
                                                                Dependent_Field_Name__c,
                                                                Dependent_Field_Label__c,
                                                                Dependent_Field_Value__c
                                                        from Community_Webform_Picklist__c
                                                        where Page__c =: page
                                                            and Language__c =: language
                                                            and Community__c =: community
                                                        order by Field_Label__c ASC, Dependent_Field_Label__c ASC];
        Set<String> catVals = new Set<String>();
        Map<String, List<CDdCommunityHelper.PicklistEntryWrapper>> catSubcatOptions = new Map<String, List<CDdCommunityHelper.PicklistEntryWrapper>>();
        if (picklists.size() > 0){
            for (Community_Webform_Picklist__c pl : picklists){
                if (!catVals.contains(pl.Field_Value__c)){
                    catVals.add(pl.Field_Value__c);
                    wrp.catOptions.add(new CDdCommunityHelper.PicklistEntryWrapper( pl.Field_Label__c,
                                                                                    pl.Field_Value__c));
                }

                List<CDdCommunityHelper.PicklistEntryWrapper> subcatList = new List<CDdCommunityHelper.PicklistEntryWrapper>();
                if (catSubcatOptions.containsKey(pl.Field_Value__c)){
                    subcatList = catSubcatOptions.get(pl.Field_Value__c);
                } else {
                    subcatList = CDdCommunityHelper.initPicklist();
                }
                subcatList.add(new CDdCommunityHelper.PicklistEntryWrapper( pl.Dependent_Field_Label__c,
                                                                            pl.Dependent_Field_Value__c));
                catSubcatOptions.put(pl.Field_Value__c, subcatList);
            }
            for (String catVal : catSubcatOptions.keySet()){
                wrp.catSubcatOptions.add(new CDdCommunityHelper.DependentPicklistEntryWrapper(  catVal,
                                                                                                catSubcatOptions.get(catVal)));
            }
        }
        return wrp;
    }

    private static CommunityWebCaseWrapper getCatOpts(CommunityWebCaseWrapper wrp, String objName, String fldName){
        if (wrp.catOptions.size() == 1){
            wrp.catOptions = CDdCommunityHelper.getCommunityPicklistValues( objName,
                                                                            fldName);
        }
        return wrp;
    }


    private static String escapeTextarea(String inputText){
        if (String.isNotBlank(inputText)){
            return inputText.escapeJava();
        } else {
            return '';
        }
    }

    public class CommunityWebCaseWrapper{
        @AuraEnabled
        public String restaurantNameLabel {get; set;}
        @AuraEnabled
        public String restaurantName {get; set;}
        @AuraEnabled
        public String storeIdLabel {get; set;}
        @AuraEnabled
        public String storeId {get; set;}
        @AuraEnabled
        public String restaurantAddressLabel {get; set;}
        @AuraEnabled
        public String restaurantAddress {get; set;}
        @AuraEnabled
        public String nameLabel {get; set;}
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String emailLabel {get; set;}
        @AuraEnabled
        public String email {get; set;}
        @AuraEnabled
        public String companyLabel {get; set;}
        @AuraEnabled
        public String company {get; set;}
        @AuraEnabled
        public String phoneLabel {get; set;}
        @AuraEnabled
        public String phone {get; set;}
        @AuraEnabled
        public String categoryLabel {get; set;}
        @AuraEnabled
        public String category {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.DependentPicklistEntryWrapper> catSubcatOptions;
        @AuraEnabled
        public String subcategoryLabel {get; set;}
        @AuraEnabled
        public String subcategory {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> catOptions;
        @AuraEnabled
        public String caviarServiceRegionLabel {get; set;}
        @AuraEnabled
        public String caviarServiceRegion {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> csrOptions;
        @AuraEnabled
        public String issueTopicLabel {get; set;}
        @AuraEnabled
        public String issueTopic {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> itOptions;
        @AuraEnabled
        public String issueCategoryLabel {get; set;}
        @AuraEnabled
        public String issueCategory {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> icOptions;
        @AuraEnabled
        public String typeOfIncidentLabel {get; set;}
        @AuraEnabled
        public String typeOfIncident {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> toiOptions;
        @AuraEnabled
        public String descriptionLabel {get; set;}
        @AuraEnabled
        public String description {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> emptyOptions;
        // New for Dasher Project W
        @AuraEnabled
        public Boolean isDasherW {get; set;}
        @AuraEnabled
        public String isCaliforniaDasherLabel {get; set;}
        @AuraEnabled
        public String isCaliforniaDasher {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> isCaliforniaDasherOptions;
        @AuraEnabled
        public String isOnDashLabel {get; set;}
        @AuraEnabled
        public String isOnDash {get; set;}
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> isOnDashOptions;
        // End for Dasher Project W

        public CommunityWebCaseWrapper(){
            this.name = '';
            this.email = '';
            this.phone = '';
            this.category = '';
            this.subcategory = '';
            this.catOptions = CDdCommunityHelper.initPicklist();
            this.catSubcatOptions = new  List<CDdCommunityHelper.DependentPicklistEntryWrapper>();
            this.emptyOptions = CDdCommunityHelper.initPicklist();
            this.typeOfIncident = '';
            this.caviarServiceRegion = '';
            this.issueTopic = '';
            this.issueCategory = '';
            this.description = '';
            // New for Dasher Project W
            this.isDasherW = CDdExperimentSvc.getFeatureFlag('Dasher_W__c');
            this.isCaliforniaDasher = '';
            this.isCaliforniaDasherOptions = CDdCommunityHelper.initPicklist();
            this.isOnDash = '';
            this.isOnDashOptions = CDdCommunityHelper.initPicklist();
            // End for Dasher Project W
        }
    }
}