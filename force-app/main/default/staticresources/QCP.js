/**
* @description : This script runs under the CPQ Quote Calculator Plugin for Page Security and Quote Calculations.
*  This script lives as record data in the CPQ SBQQ__CustomScript__c object, but is checked in to git for versioning.
*  Updates need to be copy and pasted into the custom script record in the org you are working.
*
* For documentation visit:
* Quote Calcluator Plugin (QCP) - https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_plugins.meta/cpq_dev_plugins/cpq_dev_jsqcp_parent.htm
* Page Security Plugin (PSP) - https://developer.salesforce.com/docs/atlas.en-us.cpq_dev_plugins.meta/cpq_dev_plugins/cpq_javascript_page_security_plugin.htm
*/
/*-------------------------------------------------------------------------------------
Page Security Plugin
-------------------------------------------------------------------------------------*/
/**
* @description : The calculator calls this method after it completes a calculation to determine if a field is visible on the line editor screen.
* @param {fieldName} : The quote line field that should be visible or not.
* @param {line} : The quote line that the field is evaluated on.
*/
export function isFieldVisible(fieldName, line) {
    // BZAP-15003: check if fieldname is in collection of visible attributes from line AND in Drawer fieldset
    let drawerFields = [];
    let visibleAttributes = [];
    if (line.SBQQ__Quote__r.Drawer_Attributes__c != null) {
        drawerFields = line.SBQQ__Quote__r.Drawer_Attributes__c.split(', ');
        if(drawerFields.includes(fieldName)){
            if(line.Visible_Configuration_Attributes__c === null || line.Visible_Configuration_Attributes__c == ''){
                return false;
            }

            visibleAttributes = line.Visible_Configuration_Attributes__c.split(', ');
            if (visibleAttributes.includes(fieldName)) {
                return true;
            }

            return false; // default to false if not found, or if field null
        }
    }
}

export function isFieldEditable(fieldName, line) {
    //Q2C-285 Original Commission ALWAYS locked
    // BZAP-16547 List Fee ALWAYS locked
    if (fieldName == 'Original_Commission__c' || fieldName == 'SBQQ__ListPrice__c') {
        return false;
    }

    //BZAP-19846 Marketing flat fee always locked for Marketplace Loyality
    if (fieldName == 'Marketing_Flat_Fee__c' && line.SBQQ__ProductName__c == 'Marketplace Loyalty') {
        return false;
    }

    //BZAP-15314 if Price_Basis_QLE_Restriction__c is set to 'Not Editable' lock Price_Basis__c
    if(fieldName == 'Price_Basis__c' && line.Price_Basis_QLE_Restriction__c == 'Not Editable'){
        return false;
    }

    //BZAP-18094 ALWAS lock Bbot Billing Frequency and Bbot Annual price
    if(fieldName == 'Bbot_Billing_Frequency__c' || fieldName == 'Bbot_Annual_Price__c'){
       return false;
    }

    //BZAP-18466; allow quantity to be edited for DD-for-business types, regardless of standalone/child status
    // BZAP-18467 same thing for trial period
    if(
        (
            fieldName == 'SBQQ__Quantity__c' ||
            fieldName == 'Trial_Period__c' ||
            fieldName == 'Trial_Fee__c'
        ) &&
        line.SBQQ__Quote__r.Opportunity_Record_Type__c == 'DoorDash for Business'
    ){
        //BZAP-18467; trial fee is only editable if trial period has been set.
        if(
            !(
                fieldName == 'Trial_Fee__c' &&
                (
                    line.Trial_Period__c == null ||
                    line.Trial_Period__c == ''
                )
            )
        ) {
            return true;
        }
    }

    //All bundle header fields are locked unless its package trial period in a post sale scenario
    if (
        line.SBQQ__RequiredBy__r === null &&
        line.Product_Standalone_Editability__c !== 'Editable' // BZAP-16207
    ) {
        if (line.SBQQ__Quote__r.Opportunity_Record_Type__c != 'Post Sale') {
            if (
                fieldName == 'Trial_Period__c' ||
                fieldName == 'Trial_Fee__c' ||
                fieldName == 'Trial_Commission__c' ||
                fieldName == 'SBQQ__SpecialPrice__c' ||
                fieldName == 'SpecialPrice_Custom__c' ||
                fieldName == 'Requested_Commission__c' ||
                fieldName == 'SBQQ__Quantity__c'
            ) {
                return false;
            }
        } else {
            if (
                fieldName == 'Trial_Fee__c' ||
                fieldName == 'Trial_Commission__c' ||
                fieldName == 'Requested_Commission__c' ||
                fieldName == 'SBQQ__Quantity__c'
            ) {
                return false;
            }

            //BZAP-14355 and changes for BZAP-13698
            if (
                (
                    fieldName == 'SBQQ__SpecialPrice__c' ||
                    fieldName == 'SpecialPrice_Custom__c'
                ) && line.SBQQ__ProductFamily__c !== 'Advertisement'
            ) {
                return false;
            }
        }
    }
    //BZAP-12962 Non-Trialable Quote Lines have the Trial_Period__c field locked for Post sales Quotes
    if (line.SBQQ__Quote__r.Opportunity_Record_Type__c == 'Post Sale') {
        if (!line.Trialable__c) {
            if (fieldName == 'Trial_Period__c') {
                return false;
            }
        }
    } else {
        //BZAP-13258 If Package Trial Period is not set, do not allow Trial Commission to be editable
        if (!line.SBQQ__Quote__r.Trial_Period_Quote__c ) {
            if (fieldName == 'Trial_Commission__c') {
                return false;
            }
        }
    }

    //Child Product Logic
    // (or parent with Product_Standalone_Editability__c is set to 'Editable' (BZAP-16207))
    if (
        line.SBQQ__RequiredBy__r != null ||
        (
            line.SBQQ__RequiredBy__r === null &&
            line.Product_Standalone_Editability__c === 'Editable'
        )
    ) {
        //Q2C-745 & BZAP-18465 Unlock for Bbot Trialable Products
        if (line.SBQQ__Quote__r.Opportunity_Record_Type__c != 'Post Sale' && line.SBQQ__ProductFamily__c != 'Bbot') {
            if (fieldName == 'Trial_Period__c') {
                return false;
            }
        }

        //BZAP-18465 Non-Trialable Quote Lines have the Trial_Period__c field locked for Bbot Pre sales Quotes
        if (line.SBQQ__Quote__r.Opportunity_Record_Type__c == 'Marketplace' &&
            line.SBQQ__ProductFamily__c == 'Bbot' && !line.Trialable__c) {
            if (fieldName == 'Trial_Period__c') {
                return false;
            }
        }

        //BZAP-12406 refactor packages should not be editable
        if(
            line.SBQQ__RequiredBy__r != null &&
            line.SBQQ__RequiredBy__r.DD_Custom_ID__c != null &&
            line.DD_Custom_ID__c != null &&
            (
                line.SBQQ__RequiredBy__r.DD_Custom_ID__c == 'MKTPKG-0000209' && line.DD_Custom_ID__c == 'MKTPL-0000200'
            ) &&
            fieldName == 'Requested_Commission__c'
        ){
            return false;
        }

        //BZAP-13698 changes for Price_Basis__c picklist values
        //Q2C-563 Commission
        if (line.Price_Basis__c == 'Commission') {
            if (line.SBQQ__RequiredBy__r != null && line.Trialable__c && line.SBQQ__RequiredBy__r.Trialable__c) {
                    if (
                    fieldName == 'Trial_Fee__c' ||
                    fieldName == 'SBQQ__SpecialPrice__c' ||
                    fieldName == 'SpecialPrice_Custom__c' ||
                    fieldName == 'SBQQ__Quantity__c'
                ) {
                    return false;
                }
            } else if (
                fieldName == 'Trial_Fee__c' ||
                fieldName == 'Trial_Commission__c' ||
                fieldName == 'SBQQ__SpecialPrice__c' ||
                fieldName == 'SpecialPrice_Custom__c' ||
                fieldName == 'SBQQ__Quantity__c'
            ) {
                return false;
            }
        }

        //Q2C-563 Fees
        if (line.Price_Basis__c == 'Flat_Commission') {
            //BZAP-13648 BZAP-13458 Use SBQQ__SpecialPrice__c for Requested Fee
            if(fieldName == 'SBQQ__SpecialPrice__c' || fieldName == 'SpecialPrice_Custom__c'){
                //Q2C-1149 Lock List Price for Cx Delivery Fee (Not Cx Delivery Fee - Storefront)
                if(line.DD_Custom_ID__c != null && line.DD_Custom_ID__c == 'MKTPL-0000119'){
                   return false;
                }
                //BZAP-12406 - Updated to include refactor packages as well. There is no Cx Delivery Fee - Storefront in future state
               if(
                    line.SBQQ__RequiredBy__r != null &&
                    line.SBQQ__RequiredBy__r.DD_Custom_ID__c != null &&
                    line.DD_Custom_ID__c != null &&
                    (
                        line.SBQQ__RequiredBy__r.DD_Custom_ID__c == 'MKTPKG-0000209' ||
                        line.SBQQ__RequiredBy__r.DD_Custom_ID__c == 'MKTPKG-0000203'
                    ) &&
                    line.DD_Custom_ID__c == 'MKTPKG-0000201'
               ){
                    return false;
               }
            }
            if (line.SBQQ__RequiredBy__r != null && line.Trialable__c && line.SBQQ__RequiredBy__r.Trialable__c) {
                if (
                    fieldName == 'Trial_Commission__c' ||
                    fieldName == 'SBQQ__Quantity__c' ||
                    fieldName == 'Requested_Commission__c'
                ) {
                    return false;
                }
            } else {
                if (
                    fieldName == 'Trial_Fee__c' ||
                    fieldName == 'Trial_Commission__c' ||
                    fieldName == 'SBQQ__Quantity__c' ||
                    fieldName == 'Requested_Commission__c'
                ) {
                    return false;
                }
            }
        }
        //Q2C-563 Commission Fee
        if (line.Price_Basis__c == 'Commission + Flat') {
            //BZAP-13648 BZAP-13458 Use SBQQ__SpecialPrice__c for Requested Fee
            if (line.SBQQ__RequiredBy__r != null && line.Trialable__c && line.SBQQ__RequiredBy__r.Trialable__c) {
                if (
                    fieldName == 'SBQQ__Quantity__c'
                ) {
                    return false;
                }
            } else {
                if (
                    fieldName == 'Trial_Fee__c' ||
                    fieldName == 'Trial_Commission__c' ||
                    fieldName == 'SBQQ__Quantity__c'
                ) {
                    return false;
                }
            }
        }
    }
}

/*-------------------------------------------------------------------------------------
Lifecycle Hooks
-------------------------------------------------------------------------------------*/
/**
* @description : The calculator calls this method before calculation begins, but after formula fields have been evaluated.
* @param {quoteLineModel[]} quoteLineModels JS array containing all lines in a quote.
* @param {quoteModel} quoteModel JS representation of the quote.
* @returns {Promise}
*/
export function onBeforeCalculate(quoteModel, quoteLineModels, conn) {
    let primaryMxCategory = quoteModel.record.Account_Primary_Merchant_Category__c ? quoteModel.record.Account_Primary_Merchant_Category__c : 'Prepared Food & Drink (Rx)';
    let dateComparison = quoteModel.record.SBQQ__StartDate__c ? convertDateString(quoteModel.record.SBQQ__StartDate__c) : 'TODAY';
    let quoteDRN = quoteModel.record.DRN__c;

    let productSearchKeys = [];
    let searchKeyData = {};

    const quoteLines = quoteLineModels.map(quoteLineModel => quoteLineModel.record);
    quoteLines.forEach(line => {
        line.Opportunity_Record_Type_Text__c = quoteModel.record.Opportunity_Record_Type__c;
        line.Deal_Desk_Submitted__c = quoteModel.record.Deal_Desk_Submitted__c;
        //Build search key for query
        if (line.SBQQ__Product__c && line.Parent_Package_Id__c && line.CurrencyIsoCode && primaryMxCategory) {
            let key = buildSearchKey(primaryMxCategory, line);
            //Don't search for keys that have already been priced.
            if (!line.Pricing_Search_Complete__c) {
                productSearchKeys.push(key);
            }
            //associate search key to relevant data
            searchKeyData[key] = {quoteLine: line, quote: quoteModel.record, rates: []};
        }
        line.SBQQ__SpecialPriceType__c = 'Custom'; // BZAP-13968
    });

    if(productSearchKeys.length > 0){
        let searchKeyList = "('" + productSearchKeys.join("', '") + "')";
        let queryString = 'SELECT Id, Name, Product__c, Package__c, CurrencyIsoCode, Primary_Merchant_Category__c, Search_Key__c, Start__c, End__c, Region__c, Submarket_Name__c, Deck_Rank__c, Segment__c, Filter_Value_1__c,';
        queryString += ' Target_Rate__c, Floor_Rate__c, Price__c, Original_Commission__c, Ceiling_Rate__c, LastModifiedDate, Ace_Basic__c, Ace_Floor__c, Pricing_Tier__c, Ceiling_Fee__c, Floor_Fee__c, User_Manager_Commission_Threshold__c,';
        queryString += ' User_Manager_Fee_Threshold__c, Deal_Desk_Commission_Threshold__c, Deal_Desk_Fee_Threchold__c, Dependent_Product__c';
        queryString += ' FROM Commission_Rate__c WHERE Start__c <= ' + dateComparison + ' AND End__c >= ' + dateComparison + ' AND Search_Key__c IN ';
        queryString += searchKeyList;
        return conn.query(queryString)
            .then(function(results){
                if (results.totalSize){
                    results.records.forEach(rate => {
                        let quoteLine =  searchKeyData[rate.Search_Key__c].quoteLine;
                        let quote =  searchKeyData[rate.Search_Key__c].quote;
                        if(quoteLine && quote){
                            //determine number of matching fields for the rate entry against the quote line
                            rate.supplementalFieldMatches = countSupplementalFieldMatches(rate, quote, quoteLine);
                        }
                        searchKeyData[rate.Search_Key__c].rates.push(rate);
                    });
                }
                //Go back through sourced quote line data and determine rate match based on best criteria and map quote line field values
                quoteLines.forEach(line => {
                    if (!line.Pricing_Search_Complete__c) {
                        let key = buildSearchKey(primaryMxCategory, line);
                        let qlRateData = searchKeyData[key];
                        if(qlRateData && qlRateData.rates.length > 0){
                            //If there are more than one rate find the one that had the most supplemental matches.
                            if(qlRateData.rates.length > 1){
                                let mostMatches = Math.max(...Array.from(qlRateData.rates, r => r.supplementalFieldMatches));
                                let bestMatchRate = qlRateData.rates.find(r => r.supplementalFieldMatches === mostMatches);
                                line = mapCommissionRateFieldsToQL(bestMatchRate, line, quoteDRN);
                            } else {
                                line = mapCommissionRateFieldsToQL(qlRateData.rates[0], line, quoteDRN);
                            }
                            //Price serch is complete
                            line.Pricing_Search_Complete__c = true;
                        }
                    }
                });
            });
    }
    return Promise.resolve();
}
/**
* @description : The calculator calls this method before it evaluates price rules.
* @param {quoteLineModel[]} quoteLineModels JS array containing all lines in a quote.
* @param {quoteModel} quoteModel JS representation of the quote.
* @returns {Promise}
*/
export function onBeforePriceRules(quoteModel, quoteLineModels) {
    // Get quote line records
    const quoteLines = quoteLineModels.map(quoteLineModel => quoteLineModel.record);
    return Promise.resolve();
}
/**
* @description : The calculator calls this method after it evaluates price rules.
* @param {quoteLineModel[]} quoteLineModels JS array containing all lines in a quote.
* @param {quoteModel} quoteModel JS representation of the quote.
* @returns {Promise}
*/
export function onAfterPriceRules(quoteModel, quoteLineModels) {
    //Get quote line records
    const quoteLines = quoteLineModels.map(quoteLineModel => quoteLineModel.record);
    //Calculate the end date of a trial if the trial start date and term(in days) are populated

    var latestTrialPeriodMap = new Map();

    quoteLines.forEach((line) => {
        //BZAP-13698
        line.SBQQ__SpecialPrice__c = line.SpecialPrice_Custom__c;

        //BZAP-18467; clear trial fee if period has been returned to 'None'
        if(
            line.SBQQ__Quote__r.Opportunity_Record_Type__c == 'DoorDash for Business' &&
            (line.Trial_Period__c == null || line.Trial_Period__c == '')
        ){
            line.Trial_Fee__c = null;
        }

        if (line.SBQQ__EffectiveStartDate__c &&
            line.Trial_Period__c &&
            line.SBQQ__ProductFamily__c !== 'Marketplace Promotion'
        ) {
            const startDate = quoteModel.record.SBQQ__StartDate__c;
            const splitStart = startDate.split("-");
            const trialEndDate = addDaysToDate(parseInt(splitStart[0]), parseInt(splitStart[1]), parseInt(splitStart[2]), parseInt(line.Trial_Period__c));
            line.Trial_Start_Date__c = startDate;
            line.Trial_EndDate__c = trialEndDate;
        }

        if (line.Price_Basis__c == 'Commission' ){
            line.SpecialPrice_Custom__c = null;
            line.SBQQ__ListPrice__c = 0;
            line.Final_Fee__c = 0;

            line.Original_Commission__c = line.Default_Commission__c == null ? 0 : line.Default_Commission__c;

            //Set final commission rate
            if (line.Record_Source__c == 'Manual') {
                line.Final_Commission__c = line.Requested_Commission__c == null ? line.Original_Commission__c : line.Requested_Commission__c;
            }
        } else if (line.Price_Basis__c == 'Flat_Commission' ) {
            line.Requested_Commission__c = null;
            line.Original_Commission__c = 0;
            line.Final_Commission__c = 0;

            line.SBQQ__ListPrice__c = line.Default_Fee__c == null ? 0 : line.Default_Fee__c;
            line.Final_Fee__c = line.SBQQ__SpecialPrice__c == null ? line.SBQQ__ListPrice__c : line.SBQQ__SpecialPrice__c;
        } else if (line.Price_Basis__c == 'Commission + Flat' ) {
            line.Original_Commission__c = line.Default_Commission__c == null ? 0 : line.Default_Commission__c;
            line.SBQQ__ListPrice__c = line.Default_Fee__c == null ? 0 : line.Default_Fee__c;

            if (line.Record_Source__c == 'Manual') {
                line.Final_Commission__c = line.Requested_Commission__c == null ? line.Original_Commission__c : line.Requested_Commission__c;
            }

            line.Final_Fee__c = line.SBQQ__SpecialPrice__c == null ? line.SBQQ__ListPrice__c : line.SBQQ__SpecialPrice__c;
        }

        //BZAP-18465 Code Begin
        if(line.Trialable__c == true && line.SBQQ__ProductFamily__c == 'Bbot'){
            if(latestTrialPeriodMap.has(line.Product_Feature__c)){
                var dummyLineList = latestTrialPeriodMap.get(line.Product_Feature__c);
                dummyLineList.push(line);
                latestTrialPeriodMap.set(line.Product_Feature__c, dummyLineList);
            } else{
                var dummyLineList = [];
                dummyLineList.push(line);
                latestTrialPeriodMap.set(line.Product_Feature__c, dummyLineList);
            }
        }
        // BZAP-18465 Code End
    });

    //BZAP-18465 setting trial period code start
    var finalTrialPeriodMap = getUpdatedTrailPeriodValues(latestTrialPeriodMap);

    quoteLines.forEach((line) => {
        if(finalTrialPeriodMap.has(line.Product_Feature__c) && line.Trialable__c == true && line.SBQQ__ProductFamily__c == 'Bbot'){
            var finalTrailRecord = finalTrialPeriodMap.get(line.Product_Feature__c);
            line.Trial_Period__c = finalTrailRecord;
        }
    });
    //BZAP-18465 code end

    //Q2C-547 get the quote line products platform to evaluate for the experience field
    const platforms = quoteLines.map(quoteLine => quoteLine.SBQQ__Product__r.Platform__c);
    let experience = '';
    if (platforms.includes('DoorDash')) {
        experience += 'DoorDash;'
    }
    if (platforms.includes('Caviar')) {
        experience += 'Caviar;'
    }
    if (platforms.includes('Storefront')) {
        experience += 'Storefront;'
    }
    quoteModel.record.Experience__c = experience;

    //Q2C-554 get the quote line DD Custom Id to evaluate for DD_Id_s__c
    const customIds = quoteLines.map(quoteLine => quoteLine.DD_Custom_ID__c);
    //Get the unique set of DD Custom Ids on quote lines
    const filteredCustomIds = customIds.filter((item, index) => customIds.indexOf(item) === index);
    let ddIds = '';
    filteredCustomIds.forEach((line) => {
        ddIds += line + ', ';
    });
    quoteModel.record.DD_Id_s__c = ddIds;

    //BZAP-13589 Removes code from Q2C-906
    const parentQLs = quoteLines.filter(ql => ql.Parent_Package_Id__c == null );
    validateDuplicateProducts(parentQLs, quoteModel);

    return Promise.resolve();
}
/**
* @description : The calculator calls this method after it completes a calculation, but before re-evaluating formula fields.
* @param {quoteLineModel[]} quoteLineModels JS array containing all lines in a quote.
* @param {quoteModel} quoteModel JS representation of the quote.
* @returns {Promise}
*/
export function onAfterCalculate(quoteModel, quoteLineModels) {
    // Get quote line records
    const quoteLines = quoteLineModels.map(quoteLineModel => quoteLineModel.record);
    quoteLines.forEach(line => {
        //Q2C-544 Map Trial fields for products that are indicated as trialable only on Marketplace deals
        //  BZAP-18467; DD for business excluded here as well, trial fields are set manually in that case.
        if (
            quoteModel.record.Opportunity_Record_Type__c !== 'Post Sale' &&
            quoteModel.record.Opportunity_Record_Type__c !== 'DoorDash for Business' &&
        //BZAP-18465 for Bbot
            !quoteModel.record.DD_Id_s__c.includes('BBOT')
        ) {
            mapTrialfields(quoteModel, line);
        }

        //Q2C-985 If there is a trial period always map trial type
        if (quoteModel.record.Trial_Period_Quote__c != null) {
            quoteModel.record.Trial_Type__c = 'Promotional Period';
        } else {
            quoteModel.record.Trial_Type__c = null;
        }
    });

    return Promise.resolve();
}
/*-------------------------------------------------------------------------------------
Helper Methods
-------------------------------------------------------------------------------------*/
/**
* @description : Sum values of a field for all quote lines passed in
* @param {quoteLines} quoteLines Array containing all lines to iterate.
* @param {fieldToSum} fieldToSum The field name to sum on quote lines.
*/
export function sumLinesByField(quoteLines, fieldToSum) {
    return quoteLines
        .filter(quoteLine => quoteLine[fieldToSum] != null)
        .reduce((total, line) => total + line[fieldToSum], 0);
}
export function addDaysToDate(year, month, day, numberOfDays) {
    month = month - 1;
    const d = new Date(year, month, day);
    d.setDate(d.getDate() + numberOfDays);
    return d.toISOString().split('T')[0];
}

export function mapTrialfields(quoteModel, line) {
    if (line.SBQQ__RequiredBy__r === null && line.SBQQ__Product__r.Trialable__c) {
        line.Trial_Period__c = quoteModel.record.Trial_Period_Quote__c;
    }
    if (line.SBQQ__RequiredBy__r != null) {
        if (line.SBQQ__RequiredBy__r.Trialable__c && line.SBQQ__Product__r.Trialable__c) {
            line.Trial_Period__c = quoteModel.record.Trial_Period_Quote__c
        }
    }
}

//BZAP-13589 Check for duplicate Product Names.  Replaces Q2C-906
export function validateDuplicateProducts(parentQuoteLines, quoteModel) {
    let productNameCompare = [];
    quoteModel.record.Duplicate_Package_Product__c = false;
    parentQuoteLines.forEach(ql => {
        if (quoteModel.record.SBQQ__Type__c !== 'Amendment'){
            if (productNameCompare.includes(ql.SBQQ__ProductName__c)){
                quoteModel.record.Duplicate_Package_Product__c = true;
            }
            else {
                productNameCompare.push(ql.SBQQ__ProductName__c);
            }
        }
    });
}
//BZAP-12492 - Determine how many supplemental field matches exist on the commission rate record
//Matches are given priority by the decimal portion.
export function countSupplementalFieldMatches(rate, quote, quoteLine){
    let matches = 0.0;
    if (rate.Filter_Value_1__c) {
        if (rate.Filter_Value_1__c == quote.Number_of_SKUs__c) {
            matches = matches + 1.1;
        } else {
            matches = matches - 0.1;
        }
    }
    if (rate.Segment__c) {
        if (rate.Segment__c == quote.Account_Segment__c) {
            matches = matches + 1.01;
        } else {
            matches = matches - 0.01;
        }
    }
    if (rate.Deck_Rank__c) {
        if (rate.Deck_Rank__c == quote.DRN__c) {
            matches = matches + 1.001;
        } else {
            matches = matches - 0.001;
        }
    }
    if (rate.Region__c) {
        if (rate.Region__c == quote.Region__c) {
            matches = matches + 1.0001;
        } else {
            matches = matches - 0.0001;
        }
    }
    return matches;
}

export function mapCommissionRateFieldsToQL(rate, quoteLine, quoteDRN){
    quoteLine.Target_Rate__c = rate.Target_Rate__c;
    quoteLine.Floor_Rate__c = rate.Floor_Rate__c;
    quoteLine.SBQQ__ListPrice__c = rate.Price__c;
    quoteLine.Default_Fee__c = rate.Price__c;
    quoteLine.Commission_Rate_Number__c = rate.Id;
    quoteLine.Original_Commission__c = rate.Original_Commission__c;
    quoteLine.Default_Commission__c = rate.Original_Commission__c;
    quoteLine.Pricing_Audit__c = 'Apex';
    quoteLine.SBQQ__OriginalPrice__c = rate.Price__c;
    quoteLine.Ceiling_Rate__c = rate.Ceiling_Rate__c;
    quoteLine.CR_Modified_Date__c = rate.LastModifiedDate;
    quoteLine.Deck_Rank_Rate__c = rate.Ace_Basic__c;
    quoteLine.Deck_Rank_Floor_Rate__c = rate.Ace_Floor__c;
    quoteLine.Merchant_Deck_Rank__c = quoteDRN;
    quoteLine.Maximum_Fee__c = rate.Ceiling_Fee__c;
    quoteLine.Minimum_Fee__c = rate.Floor_Fee__c;
    quoteLine.User_Manager_Commission_Threshold__c = rate.User_Manager_Commission_Threshold__c;
    quoteLine.User_Manager_Fee_Threshold__c = rate.User_Manager_Fee_Threshold__c;
    quoteLine.Deal_Desk_Commission_Threshold__c = rate.Deal_Desk_Commission_Threshold__c;
    quoteLine.Deal_Desk_Fee_Threshold__c = rate.Deal_Desk_Fee_Threchold__c;
    quoteLine.Dependent_Product__c = rate.Dependent_Product__c;
    return quoteLine;
}

export function buildSearchKey(primaryMxCategory, quoteLine){
    return quoteLine.SBQQ__Product__c + quoteLine.Parent_Package_Id__c + quoteLine.CurrencyIsoCode + primaryMxCategory;
}

export function convertDateString(startDate) {
    const splitStart = startDate.split("-");
    //In the date construtor, Month is zero based, so we must subtract 1.
    const quoteStartDate = new Date(parseInt(splitStart[0]), parseInt(splitStart[1])-1, parseInt(splitStart[2]));

    return quoteStartDate.toISOString().split('T')[0];
}

/**
* @description : BZAP-18465 - Update the Trail Period Values with the updated Trail Period for any line
* @param {quoteLifinalTrialPeriodMapnes} finalTrialPeriodMap Map contains Product Feature Id with Updated Trail Period Value
*/
export function getUpdatedTrailPeriodValues(latestTrialPeriodMap){
    var finalTrialPeriodMap = new Map();
    latestTrialPeriodMap.forEach((values,keys)=>{
        var trialPeriod1;
        var trailPeriodList1 = [];
        var trailPeriodList2 = [];
        if(values.length > 2){
            values.forEach((line) => {
                var dummyTrial = line.Trial_Period__c == null ? "" : line.Trial_Period__c;
                if(trialPeriod1 == undefined){
                    trialPeriod1 = dummyTrial;
                    trailPeriodList1.push(dummyTrial);
                } else if(trialPeriod1 == dummyTrial){
                    trailPeriodList1.push(dummyTrial);
                } else{
                    trailPeriodList2.push(dummyTrial);
                }
            });
            if(values.length != trailPeriodList1.length && values.length !=trailPeriodList2.length){
                if(trailPeriodList2.length < trailPeriodList1.length){
                    finalTrialPeriodMap.set(keys, trailPeriodList2[0]);
                } else{
                    finalTrialPeriodMap.set(keys, trailPeriodList1[0]);
                }
            }
        }
    });
    return finalTrialPeriodMap;
}
/*-------------------------------------------------------------------------------------
Quote Line Fields
-------------------------------------------------------------------------------------
Trial_Start_Date__c
Trial_EndDate__c
Trial_Period__c
Original_Commission__c
SBQQ__EffectiveStartDate__c
SBQQ__StartDate__c
Price_Basis__c
SBQQ__RequiredBy__c
Opportunity_Record_Type_Text__c
Deal_Desk_Submitted__c
Trial_Fee__c
Trial_Commission__c
Record_Source__c
SBQQ__OptionLevel__c
DD_Custom_ID__c
Fee_Type__c
Trialable__c
Requested_Fee__c
SBQQ__PriceEditable__c
SBQQ__UpgradedSubscription__c
SBQQ__OptionLevel__c
SBQQ__ProductFamily__c
SBQQ__Product__c
Parent_Package_Id__c
CurrencyIsoCode
Pricing_Search_Complete__c
SBQQ__ListPrice__c
User_Manager_Commission_Threshold__c
Deal_Desk_Commission_Threshold__c
User_Manager_Fee_Threshold__c
Deal_Desk_Fee_Threshold__c
Minimum_Fee__c
Floor_Rate__c
Maximum_Fee__c
Ceiling_Rate__c
Target_Rate__c
Commission_Rate_Number__c
Pricing_Audit__c
SBQQ_OriginalPrice__c
CR_Modified_Date__c
Deck_Rank_Rate__c
Deck_Rank_Floor_Rate__c
Merchant_Deck_Rank__c
Dependent_Product__c
SBQQ__ProductName__c
Price_Basis_QLE_Restriction__c
SBQQ__SpecialPrice__c
Default_Fee__c
Default_Commission__c
Visible_Configuration_Attributes__c
Product_Standalone_Editability__c
Bbot_Billing_Frequency__c
Bbot_Annual_Price__c
Product_Feature__c
Marketing_Flat_Fee__c
*/

/*-------------------------------------------------------------------------------------
Quote Fields
-------------------------------------------------------------------------------------
SBQQ__StartDate__c
Opportunity_Record_Type__c
Experience__c
DD_Id_s__c
Trial_Period_Quote__c
Trial_Period_Compare__c
Trial_Type__c
SBQQ__Type__c
Account_Primary_Merchant_Category__c
Region__c
Submarket__c
DRN__c
Account_Segment__c
Number_of_SKUs__c
Duplicate_Package_Product__c
Drawer_Attributes__c
*/
