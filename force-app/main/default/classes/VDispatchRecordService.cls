public with sharing class VDispatchRecordService {
    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
    public static final Dispatch_Settings__c SETTINGS = Dispatch_Settings__c.getInstance();

    public VDispatchRecordService() {

    }

    /**
        @param deliveryInfoList The delivery information returned from Delivery API call.
    */
    public void upsertDeliveryInfo(List<VDeliveryInformation> deliveryInfoList) {
        List<VDeliveryInformation> filteredDeliveryInfo = filterDeliveryInfo(deliveryInfoList);
        System.debug(filteredDeliveryInfo);
        upsertCustomer(filteredDeliveryInfo);
        upsertDasher(filteredDeliveryInfo);
        upsertMerchant(filteredDeliveryInfo);
        upsertDelivery(filteredDeliveryInfo);
        upsertCase(filteredDeliveryInfo);
    }

    /**
     * @author      Mahesh Chouhan
     * @date        Aug 2023
     * @jira        BASD-51795
     * @description Prevent Dispatch Update for cases with particular Issue Type
     */
    public List<VDeliveryInformation> filterDeliveryInfo(List<VDeliveryInformation> deliveryInfoList){
        List<VDeliveryInformation> filteredDeliveryInfo = new List<VDeliveryInformation>();
        List<String> exclueIssueType = CDdNameValuePairHelper.getTextValue(CDdNameValuePairConstants.PREVENT_DISPATCH_UPDATE_ISSUE_TYPE)
                                        .split(CDdCoreConstants.DELIMITER_SEMICOLON);
        for(VDeliveryInformation info : deliveryInfoList){
            if(info.salesforceCase != null) {
                Case cseRec = info.salesforceCase;
                if(cseRec.Issue_Type__c != null){
                    if(!exclueIssueType.contains(cseRec.Issue_Type__c)){
                        filteredDeliveryInfo.add(info);
                    }
                }
                else {
                    filteredDeliveryInfo.add(info);
                }
            }
            else {
                filteredDeliveryInfo.add(info);
            }
        }
        return filteredDeliveryInfo;
    }

    public void upsertCasesWithoutDeliveryIds(Set<String> chatKeys, List<Case> noDeliveryNumberList) {
        Map<String, LiveChatTranscript> transcriptMap = new Map<String, LiveChatTranscript>();

        Set<double> customerNumbers = new Set<double>();
        Set<double> dasherNumbers = new Set<double>();
        Set<String> merchantNumbers = new Set<String>();

        for(LiveChatTranscript t : [select Id, CustomerNo__c, DasherNo__c,
                MerchantNo__c, ChatKey from LiveChatTranscript
            where ChatKey in :chatKeys
            and ChatKey != null]) {

            Integer counter = 0;
            double reference = null;
            Set<double> referenceSet = null;
            Set<String> strReferenceSet = null;
            Boolean isMxNo = false;

            if(t.CustomerNo__c != null) {
                counter++;
                reference = t.CustomerNo__c;
                referenceSet = customerNumbers;
            }

            if(t.DasherNo__c != null) {
                counter++;
                reference = t.DasherNo__c;
                referenceSet = dasherNumbers;
            }

            if(t.MerchantNo__c != null) {
                counter++;
                isMxNo = true;
                reference = t.MerchantNo__c;
                strReferenceSet = merchantNumbers;
            }

            if(counter == 1 && reference != null) {
                if (isMxNo) {
                    strReferenceSet.add(String.valueOf(reference).indexOf('.') != -1 ? String.valueOf(reference).substringBefore('.') : String.valueOf(reference));
                } else {
                    referenceSet.add(reference);
                }
                transcriptMap.put(t.ChatKey, t);
            }

        }


        Map<double, Account> customerMap = new Map<double, Account>();
        Map<double, Account> dasherMap = new Map<double, Account>();
        Map<String, Account> merchantMap = new Map<String, Account>();

        for(Account acc : [select Id, CustomerNo__pc, PersonContactId, IsPersonAccount
            from Account
            where CustomerNo__pc in :customerNumbers
            and CustomerNo__pc != null]) {
            customerMap.put(acc.CustomerNo__pc, acc);
        }

        for(Account acc : [select Id, DasherNo__pc, PersonContactId, IsPersonAccount
            from Account
            where DasherNo__pc in :dasherNumbers
            and DasherNo__pc != null]) {
            dasherMap.put(acc.DasherNo__pc, acc);
        }

        for(Account acc : [select Id, Restaurant_ID__c, IsPersonAccount
            from Account
            where Restaurant_ID__c in :merchantNumbers
            and Restaurant_ID__c != null]) {
            merchantMap.put(acc.Restaurant_ID__c, acc);
        }

        for(Case c : noDeliveryNumberList) {
            VDispatchRecordService.clearFieldsOnError(c);

            LiveChatTranscript t = transcriptMap.get(c.ChatKey__c);

            if(t != null) {
                Account referenceAccount = null;
                ID referenceContactId = null;
                String customerType = null;

                if(t.CustomerNo__c != null) {
                    referenceAccount = customerMap.get(t.CustomerNo__c);
                    customerType = 'Consumer';
                } else if(t.DasherNo__c != null) {
                    referenceAccount = dasherMap.get(t.DasherNo__c);
                    customerType = 'Dasher';
                } else if(t.MerchantNo__c != null) {
                    referenceAccount = merchantMap.get(String.valueOf(t.MerchantNo__c).indexOf('.') != -1 ? String.valueOf(t.MerchantNo__c).substringBefore('.') : String.valueOf(t.MerchantNo__c));
                    customerType = 'Merchant';
                }

                if(referenceAccount != null) {
                    c.AccountId = referenceAccount.Id;
                    c.Account_name__c = referenceAccount.Id;
                    c.ContactId = null;

                    c.Customer_Type__c = customerType;
                    c.DispatchRQStatus__c = 'Success';
                    c.DispatchRQAttempts__c = 0;
                    c.DispatchRQResponse__c = null;
                    c.DispatchCalloutException__c = null;
                } else {
                    c.DispatchRQStatus__c = 'Failure';
                    c.DispatchRQAttempts__c = 0;
                    c.DispatchRQResponse__c = null;
                    c.DispatchCalloutException__c = Label.vDispatchCouldNotFindAccount;
                }
            } else {
                c.DispatchRQStatus__c = 'Failure';
                c.DispatchRQAttempts__c = 0;
                c.DispatchRQResponse__c = null;
                c.DispatchCalloutException__c = Label.vDispatchCouldNotFindAccount;
            }
        }

        update noDeliveryNumberList;
    }

    public static void clearFieldsOnError(Case c) {
        c.Delivery__c = null;
        /*c.CustomerPhone__c = null;
        c.DasherPhone__c = null;
        c.MerchantPhone__c = null;*/
    }

    /**
        @param deliveryId The deliveryId passed into live agent.
        @param customerId The customerId passed into live agent (if it exists)
        @param dasherId The dasherId passed into live agent (if it exists)
        @param merchantId The merchantId passed into live agent (if it exists)
    */
    /*public VDeliveryInformation upsertDeliveryInfoFromLiveAgentInfo(Decimal deliveryId,
        Decimal customerId, Decimal dasherId, Decimal merchantId) {
        VDeliveryInformation info = new VDeliveryInformation();
        Account[] pRelatedAccount = null;

        info.liveAgentCustomerId = customerId;
        info.liveAgentDasherId = dasherId;
        info.liveAgentMerchantId = merchantId;
        info.deliveryId = deliveryId;
        info.customerId = customerId;
        info.dasherId = dasherId;
        info.merchantId = merchantId;

        if(customerId != null) {
            pRelatedAccount = [select Id from Account where CustomerNo__pc = :customerId];

            if(pRelatedAccount.size() == 1) {
                info.customerAccount = pRelatedAccount[0];
            }
        } else if(dasherId != null) {
            pRelatedAccount = [select Id from Account where DasherNo__pc = :dasherId];

            if(pRelatedAccount.size() == 1) {
                info.dasherAccount = pRelatedAccount[0];
            }
        } else if(merchantId != null) {
            pRelatedAccount = [select Id from Account where MerchantNo__c = :merchantId];

            if(pRelatedAccount.size() == 1) {
                info.merchantAccount = pRelatedAccount[0];
            }
        }

        List<VDeliveryInformation> infoList = new List<VDeliveryInformation> { info };

        upsertDelivery(infoList);
        upsertCase(infoList);

        return info;
    }*/

    public void upsertCustomer(List<VDeliveryInformation> deliveryInfoList) {
        try{
            if(SETTINGS.Customer_PA_Upsert__c) {
                Set<double> customerNumbers = new Set<double>();
                Map<double, Account> personAccountMap = new Map<double, Account>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    if(info.customerId != null) {
                        customerNumbers.add(info.customerId);
                    }
                }
                if (customerNumbers.isEmpty()) {
                    return;
                }
                for(Account acc : [select Id, CustomerNo__pc, LastName, FirstName,
                    PersonEmail, Phone
                    from Account where CustomerNo__pc in :customerNumbers
                    and CustomerNo__pc != null]) {
                    personAccountMap.put(acc.CustomerNo__pc, acc);
                }

                List<Account> toUpsert = new List<Account>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    Account acc = personAccountMap.get(info.customerId);
                    Boolean isValidChange = (acc == null || acc.FirstName != info.customerFirstName || acc.LastName != info.customerLastName
                    || acc.PersonEmail != info.customerEmail || acc.Phone != info.customerPhoneNumber || acc.CustomerNo__pc != info.customerId
                    || SETTINGS.Disable_Update_Check__c);

                    if(acc == null) {
                        acc = new Account();
                    }

                    if(isValidChange){
                        acc.FirstName = info.customerFirstName;
                        acc.LastName = info.customerLastName;
                        acc.PersonEmail = info.customerEmail;
                        acc.Phone = info.customerPhoneNumber;
                        acc.CustomerNo__pc = info.customerId;

                        toUpsert.add(acc);
                    }
                    info.customerAccount = acc;
                }

                if(toUpsert.size() > 0) {
                    upsert toUpsert;
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('VDispatchRecordService','upsertCustomer', ex);
        }
    }

    public void upsertDasher(List<VDeliveryInformation> deliveryInfoList) {
        try{
            if(SETTINGS.Dasher_PA_Upsert__c) {
                Set<double> dasherNumbers = new Set<double>();
                Map<double, Account> personAccountMap = new Map<double, Account>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    if(info.dasherId != null) {
                        dasherNumbers.add(info.dasherId);
                    }
                }
                if (dasherNumbers.isEmpty()) {
                    return;
                }
                for(Account acc : [select Id, DasherNo__pc, LastName, FirstName,
                    PersonEmail, Phone
                    from Account
                    where DasherNo__pc in :dasherNumbers
                    and DasherNo__pc != null]) {
                    personAccountMap.put(acc.DasherNo__pc, acc);
                }

                List<Account> toUpsert = new List<Account>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    Account acc = personAccountMap.get(info.dasherId);
                    Boolean isValidChange = (acc == null || acc.FirstName != info.dasherFirstName || acc.LastName != info.dasherLastName
                    || acc.PersonEmail != info.dasherEmail || acc.Phone != info.dasherPhoneNumber || acc.DasherNo__pc != info.dasherId
                    || SETTINGS.Disable_Update_Check__c);

                    if(acc == null) {
                        acc = new Account();
                    }

                    if(info.dasherId != null && isValidChange) {
                        acc.FirstName = info.dasherFirstName;
                        acc.LastName = info.dasherLastName;
                        acc.PersonEmail = info.dasherEmail;
                        acc.Phone = info.dasherPhoneNumber;
                        acc.DasherNo__pc = info.dasherId;

                        toUpsert.add(acc);
                    }
                    info.dasherAccount = acc;
                }

                if(toUpsert.size() > 0) {
                    upsert toUpsert;
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('VDispatchRecordService','upsertDasher', ex);
        }
    }

    public void upsertMerchant(List<VDeliveryInformation> deliveryInfoList) {
        try{
            if(SETTINGS.Merchant_Upsert__c) {
                Set<String> merchantIds = new Set<String>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    merchantIds.add(String.valueOf(info.merchantId.longValue()));
                }

                Map<String, Account> accountMap = new Map<String, Account>();

                for(Account acc : [ select  Id, Phone, Business_ID__c, BillingStreet, BillingCity,
                                            Restaurant_ID__c, BillingStateCode, BillingPostalCode,
                                            Name, BillingCountryCode, IsPartner__c, Order_Protocol__c
                                    from Account
                                    where Restaurant_ID__c in :merchantIds
                                        and Restaurant_ID__c != null]) {
                    accountMap.put(acc.Restaurant_ID__c, acc);
                }

                List<Account> toUpsertAccts = new List<Account>();
                List<Lead> toUpsertLeads = new List<Lead>();
                Map<Lead, Account> leadToAccountMap = new Map<Lead, Account>();
                Id leadRecordTypeId = null;

                for(VDeliveryInformation info : deliveryInfoList) {
                    Boolean isNewAcct = false;
                    Account acc = accountMap.get(String.valueOf(info.merchantId.longValue()));
                    if(acc == null) {
                        acc = new Account(RecordTypeId = SETTINGS.Merchant_Account_Record_Type_ID__c);
                        isNewAcct = true;
                    }

                    if(info.merchantId != null) {
                        String restaurantID = (info.merchantId == 0 || info.merchantId == null) ? '' : String.valueOf(info.merchantId.longValue());
                        Boolean isValidChange = isNewAcct || (String.isBlank(acc.Name) && acc.Name != info.merchantName) ||( acc.Phone != info.merchantPhoneNumber || acc.Restaurant_ID__c != restaurantID )
                            || (info.merchantBusinessId != null && info.merchantBusinessId != 0 && acc.Business_ID__c != info.merchantBusinessId) || (!String.isBlank(info.merchantStreet) && acc.BillingStreet != info.merchantStreet)
                            || (!String.isBlank(info.merchantCity) && acc.BillingCity != info.merchantCity) || (!String.isBlank(info.merchantState) && acc.BillingStateCode != info.merchantState)
                            || (!String.isBlank(info.merchantZipCode) && acc.BillingPostalCode != info.merchantZipCode) || (!String.isBlank(info.merchantCountry) && acc.BillingCountryCode != info.merchantCountry)
                            || (acc.IsPartner__c != info.merchantIsPartner) || (acc.Order_Protocol__c != info.merchantOrderProtocol) || SETTINGS.Disable_Update_Check__c;


                        if(isValidChange) {
                            if (String.isBlank(acc.Name)){
                                acc.Name = info.merchantName;
                            }
                            acc.Phone = info.merchantPhoneNumber;
                            acc.Restaurant_ID__c = (info.merchantId == 0 || info.merchantId == null) ? '' : String.valueOf(info.merchantId.longValue());
                            if (info.merchantBusinessId != null && info.merchantBusinessId != 0) {
                                acc.Business_ID__c = info.merchantBusinessId;
                            }
                            if (!String.isBlank(info.merchantStreet)){
                                acc.BillingStreet = info.merchantStreet;
                            }
                            if (!String.isBlank(info.merchantCity)){
                                acc.BillingCity = info.merchantCity;
                            }
                            if (!String.isBlank(info.merchantState)){
                                acc.BillingStateCode = info.merchantState;
                            }
                            if (!String.isBlank(info.merchantZipCode)){
                                acc.BillingPostalCode = info.merchantZipCode;
                            }
                            if (!String.isBlank(info.merchantCountry)){
                                acc.BillingCountryCode = info.merchantCountry;
                            }
                            acc.IsPartner__c =  info.merchantIsPartner;

                            /*
                            if(info.merchantSubmarket != null) {
                                acc.Market_Area__c = info.merchantSubmarket;
                            }
                            */

                            acc.Order_Protocol__c = info.merchantOrderProtocol;
                            acc.IgnoreVR__c = true;

                            toUpsertAccts.add(acc);
                        }
                        info.merchantAccount = acc;
                        if (isNewAcct && !info.merchantIsPartner) {
                            // this is a new non-partner entering the system
                            // create a lead
                            if (leadRecordTypeId == null) {
                                leadRecordTypeId = [SELECT Id FROM RecordType
                                                    WHERE SobjectType = 'Lead'
                                                    AND DeveloperName = 'Master_Lead' LIMIT 1][0].Id;
                            }
                            //Lead lead = new Lead(RecordTypeId = SETTINGS.MerchantLeadRecordType__c);
                            Lead lead = new Lead(RecordTypeId = leadRecordTypeId);
                            lead.LastName = '[Unknown]';
                            lead.LeadSource = 'Support Inbound';
                            lead.Company = info.merchantName;
                            lead.Phone = info.merchantPhoneNumber;
                            lead.Street = info.merchantStreet;
                            lead.City = info.merchantCity;
                            lead.StateCode = info.merchantState;
                            lead.PostalCode = info.merchantZipCode;
                            lead.CountryCode = info.merchantCountry;
                            lead.Store_ID__c = (info.merchantId == 0 || info.merchantId == null) ? '' : String.valueOf(info.merchantId.longValue());
                            if (info.merchantBusinessId != null && info.merchantBusinessId != 0) {
                            lead.Business_ID__c = info.merchantBusinessId;
                            }
                            lead.Status = 'Untouched';

                            // Need this because this is a hard-coded id from prod
                            // This points to the queue for Support Inbound
                            if (!Test.isRunningTest()) {
                            lead.OwnerId = '00G1a000001k3bk';
                            } else {
                            lead.Validation_Bypass__c = true;
                            }

                            info.merchantLead = lead;
                            leadToAccountMap.put(lead, acc);

                            toUpsertLeads.add(lead);
                        }
                    }

                }

                if(toUpsertAccts.size() > 0) {
                    upsert toUpsertAccts;
                }

                if(toUpsertLeads.size() > 0) {
                    for (Lead lead : toUpsertLeads) {
                        lead.Account__c = leadToAccountMap.get(lead).Id;
                    }
                    upsert toUpsertLeads;
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('VDispatchRecordService','upsertMerchant', ex);
        }
    }

    public void upsertDelivery(List<VDeliveryInformation> deliveryInfoList) {
        try{
            if(settings.Delivery_Upsert__c) {
                Set<double> deliveryIds = new Set<double>();
                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                Set<String> deliveryUUIDs = new Set<String>();
                Map<double, Delivery__c> deliveryIdMap = new Map<double, Delivery__c>();
                Map<String, Delivery__c> deliveryUUIDMap = new Map<String, Delivery__c>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                    if (String.isNotBlank(info.deliveryUUID)){
                        deliveryUUIDs.add(info.deliveryUUID);
                    }
                    if(info.deliveryId != null){
                        deliveryIds.add(info.deliveryId);
                    }

                }

                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                for(Delivery__c d : [select Id, DeliveryNo__c, DeliveryUUID__c, Merchant__c, DeliveryDestination__c,
                    DeliveryDate__c, MerchantNo__c, CustomerNo__c, DasherNo__c, Customer__c, Dasher__c
                    from Delivery__c
                    where ( DeliveryUUID__c in :deliveryUUIDs)]) {
                    if (String.isNotBlank(d.DeliveryUUID__c)){
                        deliveryUUIDMap.put(d.DeliveryUUID__c, d);
                    } else {
                        deliveryIdMap.put(d.DeliveryNo__c, d);
                    }
                }

                List<Delivery__c> toUpsert = new List<Delivery__c>();

                // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                for(VDeliveryInformation info : deliveryInfoList) {
                    //upsert Delivery only if DeliveryCurrent - BIZS-1875
                    Boolean processDeliveryInfo=false;
                    if(info.isDeliveryCurrent != null && info.isDeliveryCurrent){
                        processDeliveryInfo=true;
                    } else if(info.isDeliveryCurrent == null){
                        processDeliveryInfo=true;
                    }
                    if(processDeliveryInfo){
                        Delivery__c d = null;
                        if (deliveryUUIDMap.containsKey(info.deliveryUUID)){
                            d = deliveryUUIDMap.get(info.deliveryUUID);
                        } else if (deliveryIdMap.containsKey(info.deliveryId)){
                            d = deliveryIdMap.get(info.deliveryId);
                        }

                        if(d == null) {
                            d = new Delivery__c();
                        }

                        d.DeliveryNo__c = info.deliveryId;
                        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                        d.DeliveryUUID__c = info.deliveryUUID;
                        if(String.isNotBlank(d.DeliveryUUID__c)) {
                            d.Name = d.DeliveryUUID__c;
                        } else {
                            d.Name = String.ValueOf(d.DeliveryNo__c);
                        }
                        if(info.deliveryDate != null) {
                            d.DeliveryDate__c = Date.valueOf(info.deliveryDate);
                        }

                        if(info.merchantAccount != null) {
                            d.Merchant__c = info.merchantAccount.Id;
                        }

                        if(info.merchantId != null) {
                            d.MerchantNo__c = info.merchantId;
                        }

                        if(info.customerAccount != null) {
                            d.Customer__c = info.customerAccount.Id;
                        }

                        if(info.customerId != null) {
                            d.CustomerNo__c = info.customerId;
                        }

                        if(info.dasherAccount != null) {
                            d.Dasher__c = info.dasherAccount.Id;
                        }

                        if(info.dasherId != null) {
                            d.DasherNo__c = info.dasherId;
                        }

                        // BZAPSUP-1588 02/03/2021 Tia Xuan - Added logic for phone on Delivery
                        d.Consumer_Phone__c = info.customerPhoneNumber;
                        d.Merchant_Phone__c = info.merchantPhoneNumber;
                        d.Dasher_Phone__c = info.dasherPhoneNumber;

                        info.delivery = d;

                        toUpsert.add(d);
                    }
                }

                if(toUpsert.size() > 0) {
                    upsert toUpsert;
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('VDispatchRecordService','upsertDelivery', ex);
        }
    }

    public void upsertCase(List<VDeliveryInformation> deliveryInfoList) {
        try{
            if(SETTINGS.Create_Case_Record__c) {
                List<Case> toUpsert = new List<Case>();

                for(VDeliveryInformation info : deliveryInfoList) {
                    Case c = new Case();

                    if(info.salesforceCase != null) {
                        c = info.salesforceCase;
                    }


                    if(c.RecordTypeId == null) {
                        c.RecordTypeId = SETTINGS.Case_Record_Type_ID__c;
                    }

                    c.BusinessHoursId = SETTINGS.Case_Default_Business_Hours__c;
                    Boolean processDeliveryInfo=false;
                    if(info.isDeliveryCurrent != null && info.isDeliveryCurrent){
                        processDeliveryInfo=true;
                    }else if(info.isDeliveryCurrent == null){
                        processDeliveryInfo=true;
                    }
                    if(processDeliveryInfo){
                        c.DeliveryNo__c = info.deliveryId;
                        // 09/2020 Tia Xuan BZAPSUP-920 - Dispatch Delivery/Order ID Obfuscation SFDC Retrofit
                        c.DeliveryUUID__c = info.deliveryUUID;
                    }

                    // BZAPSUP-1588 02/03/2021 Tia Xuan - Added logic for phone on Delivery
                    // 03/01/2021 Tia Xuan rollback
                    c.CustomerPhone__c = info.customerPhoneNumber;
                    c.MerchantPhone__c = info.merchantPhoneNumber;
                    c.DasherPhone__c = info.dasherPhoneNumber;

                    //System.debug('info.chatButtonId = ' + info.chatButtonId);

                    //Here we check the chatButtonId passed from the chat details
                    //If the ids match each case below, we know the context of the form and which button it came from
                    //This needs contains because equals was not matching correctly
                    if (info.chatButtonId != null) {
                        if (info.chatButtonId.containsIgnoreCase('5731a00000005i4')) {
                            c.Customer_Type__c = 'Consumer';
                        }
                        if (info.chatButtonId.containsIgnoreCase('5731a00000005iJ')) {
                            c.Customer_Type__c = 'Dasher';
                        }
                        if (info.chatButtonId.containsIgnoreCase('5731a00000005iE')) {
                            c.Customer_Type__c = 'Merchant';
                        }
                    } else {
                        if(info.liveAgentCustomerId != null) {
                            c.Customer_Type__c = 'Consumer';
                        } else if(info.liveAgentDasherId != null) {
                            c.Customer_Type__c = 'Dasher';
                        } else if(info.liveAgentMerchantId != null) {
                            c.Customer_Type__c = 'Merchant';
                        }
                    }

                    if(info.liveAgentCustomerId != null) {
                        c.Consumer_ID__c = info.liveAgentCustomerId;
                        if(info.customerAccount != null && c.AccountId != info.customerAccount.Id) {
                            c.AccountId = info.customerAccount.Id;
                            c.Account_name__c = info.customerAccount.Id;
                            // BZAPSUP-798 Tia Xuan 08/2020
                            // Update Dispatch Callout to not wipeout the Contact.
                            //c.ContactId = null;
                        }
                    }
                    if(info.liveAgentDasherId != null) {
                        c.Dasher_ID__c = info.liveAgentDasherId;
                        if(info.dasherAccount != null && c.AccountId != info.dasherAccount.Id) {
                            c.AccountId = info.dasherAccount.Id;
                            c.Account_name__c = info.dasherAccount.Id;
                            // BZAPSUP-798 Tia Xuan 08/2020
                            // Update Dispatch Callout to not wipeout the Contact.
                            //c.ContactId = null;
                        }
                    }
                    if(info.liveAgentMerchantId != null) {
                        if(info.merchantAccount != null && c.AccountId != info.merchantAccount.Id) {
                            c.AccountId = info.merchantAccount.Id;
                            c.Account_name__c = info.merchantAccount.Id;
                            c.Merchant_Name__c = info.merchantName;
                            // BZAPSUP-798 Tia Xuan 08/2020
                            // Update Dispatch Callout to not wipeout the Contact.
                            //c.ContactId = null;
                        }
                    }
                    if (info.liveAgentCustomerId == null && info.liveAgentDasherId == null && info.liveAgentMerchantId == null) {
                        // no live agent information passed in. indicating that this is a bad request
                        // or customer type has been set to something other than what we are expecting
                        // clear out lookup fields if requested
                        VDispatchRecordService.clearFieldsOnError(c);
                    }

                    if(info.delivery != null) {
                        c.Delivery__c = info.delivery.Id;
                    }

                    // BZAPSUP-786 Tia Xuan 08/2020
                    // Update Dispatch Callout Result with Platform Field
                    c.Platform__c = info.customerExperience;

                    // BZAPSUP-1658 Tia Xuan 02/2021
                    c.Country__c = info.merchantCountryFromResponse;

                    if(info.merchantBusinessVerticalId != null) {
                        c.Business_Vertical_ID__c = info.merchantBusinessVerticalId;
                        Map<String, Business_Vertical_Mapping__mdt> businessVerticalMap = CDdCustomMetadata.getBusinessVerticalMappings();
                        if(businessVerticalMap.containsKey(info.merchantBusinessVerticalId)) {
                            c.Vertical_Type__c =  businessVerticalMap.get(info.merchantBusinessVerticalId).Business_Vertical_Type__c;
                        }
                    }

                    toUpsert.add(c);
                    info.salesforceCase = c;
                }

                if(toUpsert.size() > 0) {
                    upsert toUpsert;
                }
            }
        }
        catch(Exception ex){
            CDdErrorUtilities.publishException('VDispatchRecordService','upsertCase', ex);
        }
    }
}