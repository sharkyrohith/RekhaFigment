/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

public with sharing class CDdActivationChecklist {
    private final String NULL_RESULT = 'One or more fields are incomplete: ';

    private final CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
    private final Case theCase;
    private final Datetime timestamp = Datetime.now();
    private final List<Case> relatedCases;
    private final List<Opportunity> relatedOpps;
    private final Map<String, Activation_Check_RecordType__mdt> checkRecordTypes;
    private final Map<String, Activation_Check__mdt> checkMeta;
    private final menuLinks menuLinks;
    private final PaymentAccount paymentAccount;
    @TestVisible private final Store store;
    private final String accountId;
    private final String storeId;
    public final Map<String, Activation_Checklist__c> checklist;
    public static Boolean isMarketplaceOnboardingEnabled = !CDdCustomMetadata.isDisabled('CDdOpportunityCaseHelper_marketplaceOnbo');
    public static Integer lowConfidence = 6;
    public static Integer mediumConfidence = 4;
    public static Integer highConfidence = 2;

    @TestVisible
    private CDdActivationChecklist(
            String storeId, Case aCase, Map<String, Activation_Checklist__c> checklist, List<Case> relatedCases,
            List<Opportunity> relatedOpportunities, Store store, PaymentAccount paymentAccount, MenuLinks menuLinks) {
        this.theCase = aCase;
        this.checklist = checklist;
        this.checkMeta = initCheckMeta();
        this.checkRecordTypes = initCheckRecordTypes();
        this.relatedCases = relatedCases;
        this.relatedOpps = relatedOpportunities;
        this.storeId = storeId;
        this.store = store;
        this.menuLinks = menuLinks;
        this.paymentAccount = paymentAccount;
    }

    public CDdActivationChecklist(Id caseId) {
        theCase = initCase(caseId);
        checklist = initChecklist();
        checkMeta = initCheckMeta();
        checkRecordTypes = initCheckRecordTypes();
        relatedCases = initRelatedCases();
        relatedOpps = initRelatedOpps();
        if (theCase.Account != null && theCase.Account.Restaurant_ID__c != null) {
            storeId = theCase.Account.Restaurant_ID__c;
            store = initStore(storeId);
            menuLinks = initMenuLinks();
            if (store != null) {
                accountId = store.payment_account_id;
                if(String.isNotBlank(store.business_id)){
                    store.business = initBusiness(store.business_id);
                }
                if(String.isNotBlank(store.address_id)){
                    store.address = initAddress(store.address_id);
                }
                if (accountId != null) {
                    paymentAccount = initPaymentAccount();
                }
            }
        }
    }

    @TestVisible
    private Map<String, Activation_Check__mdt> initCheckMeta() {
        Map<String, Activation_Check__mdt> stepsMap = new Map<String, Activation_Check__mdt>();
        List<Activation_Check__mdt> steps = [select DeveloperName, Name__c, Order__c, Target__c from Activation_Check__mdt];
        for (Activation_Check__mdt step: steps) {
            stepsMap.put(step.DeveloperName, step);
        }
        return stepsMap;
    }

    @TestVisible
    private Map<String, Activation_Check_RecordType__mdt> initCheckRecordTypes() {
        Map<String, Activation_Check_RecordType__mdt> stepsMap = new Map<String, Activation_Check_RecordType__mdt>();
        List<Activation_Check_RecordType__mdt> types = [select DeveloperName, RecordTypes__c from Activation_Check_RecordType__mdt];
        for (Activation_Check_RecordType__mdt type: types) {
            stepsMap.put(type.DeveloperName, type);
        }
        return stepsMap;
    }

    private Case initCase(String caseId) {
        Case theCase = [
                select
                        Id,
                        Status,
                        RecordType.DeveloperName,
                        Account.Bank_Account_Number_Encrypted__c,
                        Account.Bank_Routing_Number_Encrypted__c,
                        Account.BillingCity,
                        Account.BillingPostalCode,
                        Account.BillingState,
                        Account.BillingStreet,
                        Account.EIN_Encrypted__c,
                        Account.Is_Active__c,
                        Account.Legal_Business_Name__c,
                        Account.Payment_Account_ID__c,
                        Account.Phone,
                        Account.Restaurant_ID__c,
                        Account.Starting_Point_ID__c,
                        Account.BillingCountryCode,
                        Account.Entity_Type__c,
                        Account.Mx_Tax_Id_VAT__c,
                        AccountId,
                        Opportunity_Name__r.Id,
                        Opportunity_Name__r.Name,
                        Opportunity_Name__r.Order_Protocol__c,
                        Opportunity_Name__r.PDOA_Delay_Reason__c,
                        Opportunity_Name__r.Proposed_Date_of_Activation__c,
                        Opportunity_Name__r.RecordTypeId,
                        Opportunity_Name__r.StageName
                from Case where Id = :caseId
        ];
        return theCase;
    }

    private Map<String, Activation_Checklist__c> initChecklist() {
        Map<String, Activation_Checklist__c> checkListMap = new Map<String, Activation_Checklist__c>();
        List<Activation_Checklist__c> checkList = [
                select
                        Id,
                        Date_Time_Ran__c,
                        Developer_Name__c,
                        Name,
                        Target__c,
                        Original_Status__c,
                        Resolved__c,
                        Result__c,
                        Status__c,
                        Time_to_Resolve__c,
                        CreatedDate
                from Activation_Checklist__c
                where Case__r.Id = :theCase.Id
                order by Order__c
        ];
        for (Activation_Checklist__c checklistItem : checkList) {
            checkListMap.put(checklistItem.Developer_Name__c, checklistItem);
        }
        return checkListMap;
    }

    private List<Case> initRelatedCases() {
        List<String> recordTypes = new List<String>();
        recordTypes.add(theCase.RecordType.DeveloperName);
        for (Activation_Check_RecordType__mdt type : checkRecordTypes.values()) {
            recordTypes.addAll(type.RecordTypes__c.split(','));
        }

        List<Case> relatedCases = [
                select
                        Id,
                        IsClosed,
                        RecordType.DeveloperName
                from Case
                where
                AccountId = :theCase.AccountId
                and Account.IsPersonAccount = false
                and IsClosed = false
                and RecordType.DeveloperName = :recordTypes
        ];
        return relatedCases;
    }

    private List<Opportunity> initRelatedOpps() {
        List<Opportunity> relatedOpps = [
                select
                        Id,
                        StageName
                from Opportunity
                where
                AccountId = :theCase.AccountId
                and Id != :theCase.Opportunity_Name__r.Id
                and RecordTypeId = :theCase.Opportunity_Name__r.RecordTypeId
                and StageName = 'Closed Won'
        ];
        return relatedOpps;
    }

         /**
    * @description Get store detail for the input Store Id
    * @param String input Store Id
    * @return Serialized store detail record from Nimda backend
    **/
    public static Store initStore(String storeId) {
        Store storeWrapper;
        try {
            //Response returning Empty string instead od empty object when data is null.
            String response = new CDdNimdaSyncMSService().getStore(storeId);
            Map<String,Object> responseMap = (Map<String,Object>)  JSON.deserializeUntyped(response);
            storeWrapper = new Store(responseMap);
        } catch (Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdActivationChecklist', 'initStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
        return storeWrapper;
    }

    /**
    * @description Get business detail for the input business Id
    * @param String input Store Id
    * @return Serialized business detail record from Nimda backend
    **/
    public static Business initBusiness(String businessId) {
        Business businessWrapper;
        try {
            String response =  new CDdNimdaSyncMSService().getBusiness(businessId);
            businessWrapper = (Business) JSON.deserialize(response, Business.class);
        } catch (Exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Business Id : ' + businessId + ' - ' + ex.getMessage()}, 'CDdActivationChecklist', 'initBusiness', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
        return businessWrapper;
    }

    /**
    * @description Get Address detail for the input address Id
    * @param String input Store Id
    * @return Serialized address detail record from Nimda backend
    **/
    private address initAddress(String addressId) {
        Address obj;
        String namedCredential;
        APICredential__mdt credentials = APICredential__mdt.getInstance('Merchant_Data_Service');
        String endpointPrefix = String.format(credentials.GETMethodSuffix__c, new List<String>{addressId});
        if(CDdMxSxConstants.isSandBox()){
            namedCredential = credentials.SandboxNamedCredential__c;
        }else{
            namedCredential = credentials.NamedCredential__c;
        }
        CDdRestJSONObj.RestAPIResponse response= connector.invokeRESTAPI('GET', null, null, null, endpointPrefix, null, namedCredential);
        if (response.statusCode == 200) {
            obj = (Address) JSON.deserialize(response.body, Address.class);
        }
        return obj;
    }

    /**
    * @description Get Payment account detail for the input payment account Id
    * @param String input accountId
    * @return Serialized Payment account detail record
    **/
    private PaymentAccount initPaymentAccount() {
        PaymentAccount obj;
        try {
            //Response returning Empty string instead od empty object when data is null.
            String response = new CDdNimdaSyncMSService().getPaymentAccount(accountId);
            obj = (PaymentAccount) JSON.deserialize(response, PaymentAccount.class);
        }catch(exception ex){
            CDdErrorUtilities.createApexLogs(new List<String>{'Payment Account Id : ' + accountId + ' - ' + ex.getMessage()}, 'CDdActivationChecklist', 'initPaymentAccount', LoggingLevel.ERROR);
        }
        return obj;
    }

    private menuLinks initMenuLinks() {

        menuLinks obj = new menuLinks();
        try{
            String menuResponse = new CDdNimdaSyncMSService().getStoreMenuLinks(storeId);
            obj = (menuLinks) JSON.deserialize(menuResponse, menuLinks.class);
        }catch(exception ex){}
        return obj;

    }

    public void performChecks() {
        //Salesforce checks
        checkCurrentCaseStatus();
        checkOpportunityStage();
        if (!isMarketplaceOnboardingEnabled) { //BZAP-6164 <- BZAP-9313
            checkOpenMenuTeamCases();
        }
        checkProposedDateOfActivation();
        checkDuplicateCases();
        checkDuplicateTabletCases();
        checkDuplicateOpportunities();
        checkSFBankInfo();

        //Nimda checks
        checkStoreOrderProtocol();
        checkOrderAndConfirmProtocol();
        checkStorePhone();
        checkStoreAddress();
        checkStoreName();
        checkIsPartner();
        checkIsActive();
        checkStoreMenu();
        checkPaymentAccount();
        checkStartingPoint();

        upsert checklist.values();

        Double successes = 0;
        for (Activation_Checklist__c step : checklist.values()) {
            if ('Pass'.equals(step.Status__c)) {
                successes++;
            }
        }

        Double successRate = (successes / checkMeta.size()) * 100;
        Case aCase = new Case();
        aCase.Id = theCase.Id;
        aCase.Checklist_Success_Rate__c = successRate;

        try {
            update aCase;
        } catch (Exception e) {
            insert new Apex_Log__c(Class_Name__c = 'CDdActivationChecklist', Method_Name__c = 'performChecks', Log_Level__c = 'Error', Log__c = e.getMessage());
        }
    }

    /**
     * Current Case is in Valid Status
     */
    @TestVisible
    private void checkCurrentCaseStatus() {
        final String developerName = 'S0001';
        final String[] validCaseStatus = new String[] {'Received', 'Open', 'Reopened', 'Opened', 'In Progress'};
        final String caseStatus = theCase.Status;

        if (validCaseStatus.contains(caseStatus)) {
            upsertStep(developerName, 'Pass', caseStatus);
        } else {
            upsertStep(developerName, 'Fail', caseStatus);
        }
    }

    /**
     * Opportunity Stage = Closed Won
     */
    @TestVisible
    private void checkOpportunityStage() {
        final String developerName = 'S0002';
        final String stageName = theCase.Opportunity_Name__r.StageName;

        if ('Closed Won'.equals(stageName)) {
            upsertStep(developerName, 'Pass', stageName);
        } else {
            upsertStep(developerName, 'Fail', stageName);
        }
    }

    /**
     * No Open Menu Team Cases
     *
     */
    @TestVisible
    private void checkOpenMenuTeamCases() {
        final String developerName = 'S0003';
        final String[] recordTypes = checkRecordTypes.get(developerName).RecordTypes__c.split(',');

        Integer result = 0;
        for (Case relatedCase : relatedCases) {
            if (recordTypes.contains(relatedCase.RecordType.DeveloperName)
                    && relatedCase.IsClosed == false
                    && relatedCase.Id != theCase.Id) {
                result++;
            }
        }
        if (result == 0) {
            upsertStep(developerName, 'Pass', String.valueOf(result) + ' Case(s) found');
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(result) + ' Case(s) found');
        }
    }

    /**
     * No Open Menu Updates Cases
     */
    @TestVisible
    private void checkMenuUpdateCases() {
        final String developerName = 'S0004';
        final String[] recordTypes = checkRecordTypes.get(developerName).RecordTypes__c.split(',');

        Integer result = 0;
        for (Case relatedCase : relatedCases) {
            if (recordTypes.contains(relatedCase.RecordType.DeveloperName) && relatedCase.IsClosed == false) {
                result++;
            }
        }
        if (result == 0) {
            upsertStep(developerName, 'Pass', String.valueOf(result) + ' Case(s) found');
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(result) + ' Case(s) found');
        }
    }

    /**
     * Proposed Date of Activation is not in the future
     */
    @TestVisible
    private void checkProposedDateOfActivation() {
        final String developerName = 'S0005';
        final Date proposedDate = theCase.Opportunity_Name__r.Proposed_Date_of_Activation__c;

        if (proposedDate == null | proposedDate <= Date.today()) {
            upsertStep(developerName, 'Pass', String.valueOf(proposedDate));
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(proposedDate) + ', PDOA Delay Reason: ' + theCase.Opportunity_Name__r.PDOA_Delay_Reason__c);
        }
    }

    /**
     * There are no Duplicate Cases
     */
    @TestVisible
    private void checkDuplicateCases() {
        final String developerName = 'S0006';

        Integer result = 0;
        for (Case relatedCase : relatedCases) {
            if (relatedCase.Id != theCase.Id
                    && relatedCase.RecordType.DeveloperName == theCase.RecordType.DeveloperName
                    && relatedCase.IsClosed == false) {
                result++;
            }
        }

        if (result == 0) {
            upsertStep(developerName, 'Pass', String.valueOf(result) + ' duplicate Case(s) found');
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(result) + ' duplicate Case(s) found');
        }
    }

    /**
     * There are no Duplicate Tablet Cases
     */
    @TestVisible
    private void checkDuplicateTabletCases() {
        final String developerName = 'S0007';
        String[] recordTypes = checkRecordTypes.get(developerName).RecordTypes__c.split(',');

        Integer result = 0;
        for (Case relatedCase : relatedCases) {
            if (recordTypes.contains(relatedCase.RecordType.DeveloperName) && relatedCase.IsClosed == false) {
                result++;
            }
        }

        if (result <= 1) {
            upsertStep(developerName, 'Pass', String.valueOf(result) + ' duplicate Case(s) found');
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(result) + ' duplicate Case(s) found');
        }
    }

    /**
     * There are no Duplicate Opportunities
     */
    @TestVisible
    private void checkDuplicateOpportunities() {
        final String developerName = 'S0008';
        final Integer result = relatedOpps.size();

        if (result == 0) {
            upsertStep(developerName, 'Pass', String.valueOf(result) + ' duplicate Opportunity(s) found');
        } else {
            upsertStep(developerName, 'Fail', String.valueOf(result) + ' duplicate Opportunity(s) found');
        }
    }

    /**
     * Bank Info - Salesforce
     */
    @TestVisible
    private void checkSFBankInfo() {
        final String developerName = 'S0009';
        final Account account = theCase.Account;
        List<String> fieldsInError = new List<String>();
        String result = 'Missing: ';

        if (account.Legal_Business_Name__c == null) {
            fieldsInError.add('Legal_Business_Name__c');
        }

        if (account.Bank_Account_Number_Encrypted__c == null) {
            fieldsInError.add('Bank_Account_Number_Encrypted__c');
        }

        //BZAP-11724 Changes for Germany start
        if (account.Bank_Routing_Number_Encrypted__c == null && !CDdI18nUtility.isCountryGermany(account.BillingCountryCode)
        && !CDdI18nUtility.isCountryNEWZEALAND(account.BillingCountryCode)) {
            fieldsInError.add('Bank_Routing_Number_Encrypted__c');
        }

        if (account.EIN_Encrypted__c == null)
        {
            //if country is germany and entitiy type equals Company then show the error
            if(account.BillingCountryCode == 'DE' && account.Entity_Type__c == 'Company')
            {
                fieldsInError.add('EIN_Encrypted__c');
            }
            //if country is New Zealand and entity type not equals to Sole proprietorship then show the error
            else if( account.BillingCountryCode == 'NZ' && account.Entity_Type__c != 'Sole proprietorship')
            {
                fieldsInError.add('EIN_Encrypted__c');
            }
            //if country not equals to New Zealand and germany then show the error.
            else if(account.BillingCountryCode != 'DE' && account.BillingCountryCode != 'NZ' && account.BillingCountryCode != 'AU')
            {
                fieldsInError.add('EIN_Encrypted__c');
            }
        }

        if (account.Mx_Tax_Id_VAT__c == null)
        {
            //if country is Australia and entity type not equals to Sole proprietorship then show the error
            if(account.BillingCountryCode == 'AU' && account.Entity_Type__c != 'Sole proprietorship')
            {
                fieldsInError.add('Mx_Tax_Id_VAT__c');
            }
        }

        if (account.BillingCountryCode == 'DE' && account.Entity_Type__c == null) {
            fieldsInError.add('Entity_Type__c');
        }
        //BZAP-11724 Changes for Germany End

        if (fieldsInError.size() > 0) {
            for (String field : fieldsInError) {
                result += field + '; ';
            }
            result = result.removeEnd('; ');
        }

        if (fieldsInError.size() == 0) {
            upsertStep(developerName, 'Pass', result);
        } else {
            upsertStep(developerName, 'Fail', result);
        }
    }

    /**
     * Store Order Protocol matches Opportunity
     */
    @TestVisible
    private void checkStoreOrderProtocol() {
        final String developerName = 'N0001';

        try {
            final String protocolStore = store.order_protocol;
            final String protocolOpp = theCase.Opportunity_Name__r.Order_Protocol__c;
            final String mappedProtocol;
            final String result = protocolStore + ' [Store]\n' + protocolOpp + ' [Opportunity]';

            switch on protocolOpp {
                when 'Android Tablet (Merchant Owns)', 'iOS Tablet (Merchant Owns)', 'Tablet (DoorDash Owns)', 'Tablet and Printer (DoorDash Owns)' {
                    mappedProtocol = 'IPAD';
                }
                when 'POS and Tablet (Merchant Owns)', 'POS and and Tablet (DoorDash Owns)', 'POS and Tablet Return Label' {
                    mappedProtocol = 'POINT_OF_SALE';
                }
                when 'Fax', 'Phone', 'Email' {
                    mappedProtocol = protocolOpp.toUpperCase();
                }
                when else {
                    mappedProtocol = protocolOpp;
                }
            }

            if (mappedProtocol.equals(protocolStore)) {
                upsertStep(developerName, 'Pass', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Order Protocol, Opportunity Order Protocol');
        }
    }

    /**
     * Store Order Protocol and Confirm Protocol are correct
     */
    @TestVisible
    private void checkOrderAndConfirmProtocol() {
        final String developerName = 'N0002';
        Boolean pass = false;

        try {
            String orderProtocol = store.order_protocol;
            String confirmProtocol = store.confirm_protocol;
            final String result = 'Store Order Protocol = ' + orderProtocol + '\nConfirm Protocol = ' + confirmProtocol;

            orderProtocol = orderProtocol.toUpperCase();
            confirmProtocol = confirmProtocol.toUpperCase();

            if (CDdExperimentSvc.getFeatureFlag('Enable_Store_Confirm_Protocol_Checklist__c')){
                if ('NO_CONFIRMATION'.equals(confirmProtocol)) { pass = true; }
                else { pass = false; }
            } else {
                switch on orderProtocol {
                    when 'IPAD', 'FAX', 'EMAIL' {
                        if ('ROBOCALL_SIMPLE'.equals(confirmProtocol)) { pass = true; }
                    }
                    when 'OTHER', 'POINT_OF_SALE', 'PHONE' {
                        if ('NO_CONFIRMATION'.equals(confirmProtocol)) { pass = true; }
                    }
                }
            }

            if (pass) {
                upsertStep(developerName, 'Pass', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Order Protocol, Store Confirm Protocol');
        }
    }

    /**
     * Store Phone matches Account Store Phone
     * 2022-06-06 - Nathalie Le Guay: Add Intl if-statement
     */
    @TestVisible
    private void checkStorePhone() {
        final String developerName = 'N0003';
        Set<String> intlCountryCodes = new Set<String>{'+64', '+61'};

        try {
            String storePhone = store.phone_number;
            String accountPhone = '' + theCase.Account.Phone;
            final String result = storePhone + ' [Store]\n' + accountPhone + ' [Account]';

            if (intlCountryCodes.contains(accountPhone.left(3))){
                String prefix = accountPhone.left(3);
                accountPhone = accountPhone.removeStart(prefix).removeStart('(').removeStart('0');
                storePhone = storePhone.removeStart(prefix).removeStart('(').removeStart('0');
            }

            storePhone = storePhone.replaceAll('[^0-9]', '').right(10);
            accountPhone = accountPhone.replaceAll('[^0-9]', '').right(10);

            if (storePhone.equals(accountPhone)) {
                upsertStep(developerName, 'Pass', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Phone Number, Account Phone Number');
        }
    }

    /**
     * Store Address matches Account Address
     */
    @TestVisible
    private void checkStoreAddress() {
        final String developerName = 'N0004';
        Decimal confidence = 1.0;

        try {
            String street1 = store == null ? '' : store.address.street;
            String street2 = '' + theCase.Account.BillingStreet;
            String city1 = store == null ? '' : store.address.city;
            String city2 = '' + theCase.Account.BillingCity;
            String state1 = store == null ? '' : store.address.state;
            String state2 = '' + theCase.Account.BillingState;
            String zip1 = store == null ? '' : store.address.zipCode;
            String zip2 = '' + theCase.Account.BillingPostalCode;

            String address1 = street1 + ' ' + city1 + ' ' +state1 + ' ' + zip1;
            String address2 = street2 + ' ' + city2 + ' ' +state2 + ' ' + zip2;

            Boolean isCountryGermany =  CDdI18nUtility.isCountryGermany(theCase.Account.BillingCountryCode);
            //BZAP-12358 changes for Germany
            if(isCountryGermany){
                address1 = street1 + ' ' + city1 + ' ' + zip1;
                address2 = street2 + ' ' + city2 + ' ' + zip2;
            }
            String result = address1 + ' [Store]\n' + address2 + ' [Account]';

            String[] addrParts1 = street1.replaceAll('[^a-zA-Z0-9 ]', '').toLowerCase().split(' ');
            String[] addrParts2 = street2.replaceAll('[^a-zA-Z0-9 ]', '').toLowerCase().split(' ');
            if(!isCountryGermany){
            // One has more fields than the other, e.g. a unit number
                if (addrParts1.size() != addrParts2.size()) { confidence -= 0.2; }

                // Presumed street number does not match (exact match lower)
                if (addrParts1.size() > 0 && addrParts2.size() > 0) {
                    if (!addrParts1[0].equals(addrParts2[0])) { confidence -= 0.3; }
                }

                // Presumed directional does not match (first letter)
                if (addrParts1.size() > 1 && addrParts2.size() > 1) {
                    if (!addrParts1[1].left(1).equals(addrParts2[1].left(1))) { confidence -= 0.1; }
                }

                // Presumed street does not match (exact match lower)
                if (addrParts1.size() > 2 && addrParts2.size() > 2) {
                    if (!addrParts1[2].equals(addrParts2[2])) { confidence -= 0.1; }
                }

                // Presumed street designator does not match (first letter)
                if (addrParts1.size() > 3 && addrParts2.size() > 3) {
                    if (!addrParts1[3].left(1).equals(addrParts2[3].left(1))) { confidence -= 0.1; }
                }
            }else{
                confidence = verifyGermanStreetAddress(confidence,street1.toLowerCase(),street2.toLowerCase());
            }
            // City and state must match (exact match lower)
            if (!city1.equals(city2)) { confidence -= 0.3; }
            //BZAP-12358 changes for Germany
            if(!isCountryGermany){
                if (!state1.equals(state2)) { confidence -= 0.3; }
            }

            // First part of zip must match, e.g. zip not +4
            String[] zipAry1 = zip1.split('-');
            String[] zipAry2 = zip2.split('-');
            if (zipAry1.size() != zipAry2.size()) { confidence -= 0.1; }
            if (!zipAry1[0].equals(zipAry2[0])) { confidence -= 0.3;}

            if (confidence == 1) {
                upsertStep(developerName, 'Pass', result);
            } else if (confidence >= 0.8) {
                upsertStep(developerName, 'Warn', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch(NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Address, Account Business Address');
        }
    }


     /*
    *Description: To verify the German street address for different scenarios
    * Secnario 1 Normal check:
                    Store :     Lautenschlaaße 25
                    Account:    Lautenschlagerstr. 25
    * Secnario 2 Street number at first on store address:
                    Store :     25 Lautenschlaaße
                    Account:    Lautenschlagerstr. 25
    * @param   confidence   Decimal -   to represent the confdence of address
    * @param   storeStreet  String  -    Street address from the Store API
    * @param   accStreet    String  -  Street address of the Account record
    * getLevenshteinDistance : will return number of
    */
    @TestVisible
    private static Decimal verifyGermanStreetAddress(Decimal confidence,String storeStreet, String accStreet){
        //to check if account doesn't have special chars and store address has special chars
        Boolean addressWithoutSpecialChars = accStreet.escapeUnicode() == accStreet && storeStreet.escapeUnicode() != storeStreet;
        //to replace Most common special character for existing accounts
        if(accStreet.contains('str.')){
            accStreet = accStreet.replace('str.', 'straße');
        }
        //check if Store and Account addresses are differred by more than 3 characters
        if(!storeStreet.equalsIgnoreCase(accStreet) && storeStreet.getLevenshteinDistance(accStreet) > 3){
            List<String> storeStreetList = storeStreet.toLowerCase().split(' ');
            List<String> accStreetList = accStreet.toLowerCase().split(' ');
            List<String> newAccStreetList = new List<String>();
            //if street address has more than 1 words
            if(storeStreetList.size()>1 && accStreetList.size() > 1){
                /*check if street number is at the start of store address
                Store :     25 Lautenschlaaße
                Account:    Lautenschlagerstr. 25*/
                Integer lastAccIndex = accStreetList.size()-1;
                if(storeStreetList[0].equalsIgnoreCase(accStreetList[lastAccIndex])){
                    newAccStreetList.add(accStreetList[lastAccIndex]);
                    newAccStreetList.addAll(accStreetList);
                    newAccStreetList.remove(lastAccIndex+1);
                    String newAccStreet = string.join(newAccStreetList,' ');
                    //newAccStreet:  Lautenschlagerstr. 25 => 25 Lautenschlagerstr.
                    Integer newLevenshtein = storeStreet.getLevenshteinDistance(newAccStreet);

                    if(addressWithoutSpecialChars && newLevenshtein > highConfidence){
                        newLevenshtein -= highConfidence;
                    }
                    if(newLevenshtein <= highConfidence){
                        return confidence;
                    }else if(newLevenshtein <= mediumConfidence){
                        confidence -= 0.2;
                    }else if(newLevenshtein <= lowConfidence){
                        confidence -= 0.3;
                    }
                }else{
                    //Street address nt in reverse Order and difference  is more than 3
                    confidence -= 0.3;
                }
            }else{
                //getLevenshteinDistance is more than 3 for single word in street address
                confidence -= 0.2;
            }
        }
        return confidence;
    }

    /**
     * Store Name, Business Name and Opportunity Name match and are valid
     */
    @TestVisible
    private void checkStoreName() {
        final String developerName = 'N0005';

        try {
            final String storeName = store.name;
            final String businessName = store.business.name;
            final String oppName = theCase.Opportunity_Name__r.Name;
            final String result = storeName + ' [Store]\n' + businessName + ' [Business]\n' + oppName + ' [Opportunity]';

            if (oppName.equals(storeName)
                    && storeName.toLowerCase().contains(businessName.toLowerCase())
                    && !storeName.toLowerCase().contains('placeholder')
                    ) {
                upsertStep(developerName, 'Pass', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Name, Store Business Name, Opportunity Name');
        }
    }

    /**
     * Store Is Partner
     */
    @TestVisible
    private void checkIsPartner() {
        final String developerName = 'N0006';
        Boolean isPartner = false;
        try {
            if (store.store_partnership!= null && String.isNotBlank(String.valueOf(store.store_partnership))) {
                isPartner = store.store_partnership.is_partner != null && Boolean.valueOf(store.store_partnership.is_partner);
            }

            if (isPartner) {
                upsertStep(developerName, 'Pass', 'Is Partner = true');
            } else {
                upsertStep(developerName, 'Fail', 'Is Partner = false');
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Partnership');
        }
    }

    /**
     * Business Is Active
     */
    @TestVisible
    private void checkIsActive() {
        final String developerName = 'N0007';
        try {
            if (store.business.active) {
                upsertStep(developerName, 'Pass', checkMeta.get(developerName).Name__c);
            } else {
                upsertStep(developerName, 'Fail', 'Is Active = false');
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Store Business Active');
        }
    }

    /**
     * Store contains at least one active Menu
     */
    @TestVisible
    private void checkStoreMenu() {
        final String developerName = 'N0008';
        try {
            Integer result = 0;
            for (Menu menuLink : menulinks.storeMenu.structure.menus) {
                if (menuLink.isActive!=null && menuLink.isActive) { result++; }
            }

            if (result > 0) {
                upsertStep(developerName, 'Pass', 'Active Store Menu Link Count = ' + result);
            } else {
                upsertStep(developerName, 'Fail', 'Active Store Menu Link Count = ' + result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Menu Link');
        }
    }
    /**
    * @description check Payment Account Details: Mulesoft making the call to the Payment Account API
    * if both (transfers_enabled && charges_enabled ) are True: Stpe => Pass, else Step =>  Fail
    * @param
    * @return
    **/
    @TestVisible
    private void checkPaymentAccount() {
        final String developerName = 'N0009';
        if (this.paymentAccount == null) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Store Id, Stripe Account Charges Enabled, Stripe Account Transfers Enabled');
            return;
        }
        Boolean transfersEnabled = paymentAccount.transfers_enabled == null ? false :  paymentAccount.transfers_enabled;
        Boolean chargesEnabled = paymentAccount.charges_enabled == null ? false :  paymentAccount.charges_enabled;
        String result = 'Order Submission Enabled: ' + chargesEnabled + '\nTransfers Enabled: ' + transfersEnabled;
        if (transfersEnabled && chargesEnabled) {
            upsertStep(developerName, 'Pass', result);
        } else {
            upsertStep(developerName, 'Fail', result);
        }
    }

    /**
     * Account Starting Point matches Merchant Portal
     */
    @TestVisible
    private void checkStartingPoint() {
        final String developerName = 'N0010';
        try {
            String result = 'Salesforce: ' + theCase.Account.Starting_Point_ID__c
                    + '\nStore: ' + store.starting_point_id;

            if (theCase.Account.Starting_Point_ID__c != null && theCase.Account.Starting_Point_ID__c == store.starting_point_id) {
                upsertStep(developerName, 'Pass', result);
            } else {
                upsertStep(developerName, 'Fail', result);
            }
        } catch (NullPointerException e) {
            upsertStep(developerName, 'Fail', NULL_RESULT + 'Starting Point Id');
        }
    }

    /**
    * Update an existing checklist step or create a new one
    *
    * @param developerName
    * @param status
    * @param result
    */
    @TestVisible
    private void upsertStep(String developerName, String status, String result) {
        Activation_Checklist__c step;
        if (checklist.keySet().contains(developerName)) {
            step = checklist.get(developerName);
        } else {
            step = new Activation_Checklist__c();
            step.Case__c = theCase.Id;
            checklist.put(developerName, step);
        }

        Activation_Check__mdt meta = checkMeta.get(developerName);
        step.Date_Time_Ran__c = timestamp;
        step.Developer_Name__c = developerName;
        step.Name = meta.Name__c;
        step.Order__c = meta.Order__c;
        step.Result__c = result;
        step.Status__c = status;
        step.Target__c = meta.Target__c;

        if (step.Original_Status__c == null) {
            step.Original_Status__c = status;
        } else if (('Pass'.equals(step.Status__c) && 'Fail'.equals(step.Original_Status__c) || step.Resolved__c == true) && step.Time_to_Resolve__c == null) {
            Decimal now = Datetime.now().getTime();
            Decimal created = step.CreatedDate.getTime();
            Decimal elapsed = (now - created)/1000/60;
            step.Time_to_Resolve__c = elapsed;
        }
    }

    public class Store {
        public Address address;
        public Boolean is_partner;
        public Business business;
        public String confirm_protocol;
        public String name;
        public String order_protocol;
        public String phone_number;
        public String payment_account_id;
        public Decimal starting_point_id;
        public String business_id;
        public String address_id;
        public StorePartnership store_partnership;

        public store(Map<String, Object> responseMap){
            this.address = (address) responseMap.get('address');
            this.business = (business) responseMap.get('business');
            this.confirm_protocol = String.valueOf(responseMap.get('confirm_protocol'));
            this.name = String.valueOf(responseMap.get('name'));
            this.order_protocol = String.valueOf(responseMap.get('order_protocol'));
            this.phone_number = String.valueOf(responseMap.get('phone_number'));
            this.payment_account_id = String.valueOf(responseMap.get('payment_account_id'));
            this.starting_point_id = Decimal.valueOf(String.valueOf(responseMap.get('starting_point_id')));
            this.business_id = String.valueOf(responseMap.get('business_id'));
            this.address_id = String.valueOf(responseMap.get('address_id'));
            if(responseMap.containsKey('store_partnership') && String.isNotBlank(String.valueOf(responseMap.get('store_partnership')))){
                this.store_partnership = new StorePartnership((Map<String, Object>) responseMap.get('store_partnership'));
            }
        }
    }

    public class Address {
        public String id;
        public String city;
        public String state;
        public String street;
        public String country;
        public String zipCode;
    }

    public class Business {
        public String name;
        public Boolean active;
    }
    public class PaymentAccount {
        public Boolean charges_enabled;
        public Boolean transfers_enabled;
    }
    public class menuLinks{
        public storeMenu storeMenu;
    }

    public class storeMenu{
        public structure structure;
    }

    public class structure{
        public List<menu> menus;
    }

    public class menu{
        public string id;
        public Boolean isActive;
    }

    public class StorePartnership {
        public Boolean is_partner;
        public StorePartnership(Map<String, Object> responseMap){
            if(responseMap.containsKey('is_partner') && String.isNotBlank(String.valueOf(responseMap.get('is_partner')))){
                    this.is_partner = Boolean.valueOf(responseMap.get('is_partner'));
            }
        }
    }
}