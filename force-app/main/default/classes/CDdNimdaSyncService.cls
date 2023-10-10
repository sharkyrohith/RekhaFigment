/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/11/2019
*
* @group Nimda
*
* @description This class is responsible to interact with external interfaces namely DSJ, Nimda and Stripe
* 
**************************************************************************************************************************************/
public class CDdNimdaSyncService {
    /**
    * @description member variable to store the business identifier
    **/
    private String businessId;
    /**
    * @description member variable to store the store identifier
    **/
    private String storeId;
    /**
    * @description member variable to store the User identifier
    **/
    private String userId;              
    /**
    * @description member variable to store the account record
    **/
    private Account account;    
    /**
    * @description member variable to store the opportunity record
    **/
    private Opportunity opportunity;
    /**
    * @description member variable to store the Nimda validator object
    **/ 
    private CDdNimdaSyncValidator validator;
    /**
    * @description member variable to store the Veltig custom settings
    **/     
    private vCS__c apiSettings = vCS__c.getInstance();
    /**
    * @description member variable to store the REST Connector Service
    **/     
    private CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
    /**
    * @description Constructor - inject the Account and Opportunity records and initialize any member variables
    * @param String input Business Id   
    * @param Account input account record   
    * @param Opportunity input opportunity record
    **/
    public CDdNimdaSyncService(String businessId, Account account, Opportunity opportunity) {
        this.businessId = businessId;
        this.account = account;
        this.opportunity = opportunity;
        this.validator = new CDdNimdaSyncValidator(this.account, this.opportunity);
        List<String> errorMessages = validator.validate();
        if (!errorMessages.isEmpty()){
            throw new CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_INITIALIZATION, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, String.join(errorMessages, ','));                
        }       
    }
    /**
    * @description Constructor - inject the Account and Opportunity records and initialize any member variables
    * @param String input Business Id
    * @param String input Store Id      
    * @param Account input account record   
    * @param Opportunity input opportunity record
    **/
    public CDdNimdaSyncService(String businessId, String storeId, Account account, Opportunity opportunity) {
        this(businessId, account, opportunity);
        this.storeId = storeId;
    }
    /**
    * @description Constructor - inject the Account and Opportunity records and initialize any member variables
    * @param String input Business Id
    * @param String input Store Id
    * @param String input User Id           
    * @param Account input account record   
    * @param Opportunity input opportunity record
    **/
    public CDdNimdaSyncService(String businessId, String storeId, String userId, Account account, Opportunity opportunity) {
        this(businessId, storeId, account, opportunity);
        this.userId = userId;
    }       
    /**
    * @description An operation that interacts with the external service to creates a store
    * REST Endpoint referenced is '/v1/stores'
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createStore() {
        CDdRestJSONObj.DoorstepStoreRequest storeReq = CDdNimdaSyncStoreHelper.getStoreRequest(CDdNimdaSyncConstants.STEP_CREATE_STORE, this.businessId, this.account, this.opportunity);
        System.debug(LoggingLevel.DEBUG, JSON.serializePretty(storeReq, true));
        CDdRestJSONObj.RestAPIResponse storeRes = connector.postDoorstep(JSON.serialize(storeReq, true), CDdNimdaSyncConstants.CREATE_STORE_ENDPOINT_SUFFIX);
        System.debug(LoggingLevel.DEBUG, storeRes);
        if (storeRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_CREATE_STORE, JSON.serialize(storeReq, true), storeRes.body);
        }        
        CDdRestJSONObj.DoorstepStoreResponse store = CDdRestJSONObj.parseStoreResponse(storeRes.body);
        // Check for response errors
        Boolean hasResponseError = (store.failures != null) || (store.detail != null);
        String responseError = hasResponseError ? ( (store.failures != null) ? store.failures.detail : ((store.detail != null) ? store.detail : '')) : '';
        if (hasResponseError) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_CREATE_STORE
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , responseError
                                            , JSON.serialize(storeReq)
                                            , JSON.serialize(store)
                                        );              
        }       
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_CREATE_STORE, JSON.serialize(storeReq), JSON.serialize(store));
    }
    /**
    * @description An operation that interacts with the external service to create a User
    * REST Endpoint referenced is '/v1/users'
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createUser() {
        if (String.isBlank(this.storeId)){
            throw new CDdNimdaSyncServiceException(
                                        CDdNimdaSyncConstants.STEP_CREATE_USER
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID
                                    );                  
        }
        if (validator.isOpportunityTypeProtocolNP()){
            throw new CDdNimdaSyncServiceException(
                                        CDdNimdaSyncConstants.STEP_CREATE_USER
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , CDdNimdaSyncConstants.ERROR_MSG_OPPORTUNITY_TYPE_NON_PARTNER
                                    );              
        }
        CDdRestJSONObj.DoorstepUserRequest userReq = new CDdRestJSONObj.DoorstepUserRequest();
        //userReq.email = this.opportunity.DM_Email__c;
        String phone_number = (this.account.BillingCountryCode.equals('AU') ? '+61' : '') + CDdStringUtil.formatPhoneNum(this.account.Phone, this.account.BillingCountryCode);
        userReq.email = phone_number + '@' + CDdNimdaSyncConstants.CREATE_USER_EMAIL_DOMAIN;
        userReq.phone_number = phone_number;
        userReq.first_name = this.account.Name;
        userReq.last_name = CDdNimdaSyncConstants.CREATE_USER_LAST_NAME_ADMIN;
        if (apiSettings.Nimda_User_Fix_Flag__c) {
            userReq.store_id = this.storeId;
            userReq.dm_email = this.opportunity.DM_Email__c;            
        }       
        CDdRestJSONObj.RestAPIResponse userRes = connector.postDoorstep(JSON.serialize(userReq, true), CDdNimdaSyncConstants.CREATE_USER_ENDPOINT_SUFFIX);
        System.debug('~~USER REQ~~');
        System.debug('User: ' + JSON.serialize(userReq, true));
        if (userRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_CREATE_USER, JSON.serialize(userReq, true), userRes.body);
        }        
        CDdRestJSONObj.DoorstepUserResponse user = (CDdRestJSONObj.DoorstepUserResponse) JSON.deserialize(userRes.body, CDdRestJSONObj.DoorstepUserResponse.class);
        System.debug('~~USER RESPONSE~~');
        System.debug('User: ' + user);
        // Check for response errors            
        if (String.isNotBlank(user.detail)) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_CREATE_USER
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , user.detail
                                            , JSON.serialize(userReq)
                                            , JSON.serialize(user)
                                        );              
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_CREATE_USER, JSON.serialize(userReq), JSON.serialize(user));             
    }
    /**
    * @description An operation that interacts with the external service to create a Merchant
    * REST Endpoint referenced is '/v1/merchants'
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createMerchant() {
        // check for validation errors
        Boolean hasValidationError = String.isBlank(this.storeId) || String.isBlank(this.userId);
        String validationError = hasValidationError ? ( String.isBlank(this.storeId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID : (String.isBlank(this.userId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_USER_ID : '')) : '';       
        if (hasValidationError){
            throw new CDdNimdaSyncServiceException(
                                        CDdNimdaSyncConstants.STEP_CREATE_MERCHANT
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , validationError
                                    );                  
        }
        CDdRestJSONObj.DoorstepMerchantRequest merchantReq = new CDdRestJSONObj.DoorstepMerchantRequest();
        System.debug('~~Merchant~~');
        System.debug('inputs: ' + this.storeId + ',' + this.userId);
        merchantReq.store = this.storeId;
        merchantReq.user = this.userId;
        CDdRestJSONObj.RestAPIResponse merchantRes = connector.postDoorstep(JSON.serialize(merchantReq, true), '/v1/merchants');
        if (merchantRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_CREATE_MERCHANT, JSON.serialize(merchantReq, true), merchantRes.body);
        }        
        System.debug('Merchant Req: ' + JSON.serialize(merchantReq, true));
        CDdRestJSONObj.DoorstepMerchantResponse merchant = (CDdRestJSONObj.DoorstepMerchantResponse) JSON.deserialize(merchantRes.body, CDdRestJSONObj.DoorstepMerchantResponse.class);
        System.debug('~~MERCHANT RESP~~');
        System.debug('Merchant: ' + merchant);
        // Check for response errors            
        if (String.isNotBlank(merchant.detail)) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_CREATE_MERCHANT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , merchant.detail
                                            , JSON.serialize(merchantReq)
                                            , JSON.serialize(merchant)
                                        );              
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_CREATE_MERCHANT, JSON.serialize(merchantReq), JSON.serialize(merchant));         
    }
    /**
    * @description Perform validation prior to generating Stripe Token
    **/     
    public void stripeTokenValidation() {
        List<String> errorMessages = new List<String>();
        Set<String> supportedBillingCountryCodes = CDdNimdaSyncConstants.NIMDA_V3_PYMT_SUPPORTED_BILLING_CODES;
        if (!supportedBillingCountryCodes.contains(this.account.BillingCountryCode)){
            errorMessages.add(String.format(CDdNimdaSyncConstants.ERROR_MSG_NIMDA_V3_PYMT_UNSUPPORTED_BILLING_CODE, new List<String>{this.account.BillingCountryCode}));
        } else {
            if ('AU'.equals(this.account.BillingCountryCode)){        
                errorMessages.addAll(validator.fieldValidator(this.opportunity, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_OPPORTUNITY));
                errorMessages.addAll(validator.fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_ACCOUNT));
                if (this.opportunity.Stripe_Account_Owner__r != null){
                    errorMessages.addAll(validator.fieldValidator(this.opportunity.Stripe_Account_Owner__r, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_CONTACT));
                }
            } else {
                errorMessages.addAll(validator.fieldValidator(this.opportunity, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_OPPORTUNITY));
                errorMessages.addAll(validator.fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_ACCOUNT_FOR_US_CAN));
                if (this.opportunity.Stripe_Account_Owner__r != null){
                    errorMessages.addAll(validator.fieldValidator(this.opportunity.Stripe_Account_Owner__r, CDdNimdaSyncConstants.VALIDATE_ACCOUNT_TOKEN_FIELDS_ON_CONTACT_FOR_US_CAN));
                }            
            }
        }                    
        if (!errorMessages.isEmpty()){
            throw new CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, String.join(errorMessages, ','));               
        }        
    }
    /**
    * @description An operation that interacts with Stripe API to create a Stripe Account Token
    * REST Endpoint referenced is 'https://api.stripe.com/v1/tokens'
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with Stripe API
    **/             
    public CDdNimdaSyncInfo createStripeAccountToken() {
        CDdRestJSONObj.StripeAccountTokenRequest req = new CDdRestJSONObj.StripeAccountTokenRequest();
        req.business_type = 'company';
        req.tos_shown_and_accepted = true;
        req.company_name = this.account.Legal_Business_Name__c;
        req.company_tax_id = this.account.EIN_Encrypted__c;
        CDdRestJSONObj.Address company_address = new CDdRestJSONObj.Address();
        if ('AU'.equals(this.account.BillingCountryCode)){
            company_address.line1 = this.account.ShippingStreet;
            company_address.city = this.account.ShippingCity;
            company_address.state = this.account.ShippingState;
            company_address.postal_code = this.account.ShippingPostalCode;
            company_address.country = this.account.ShippingCountryCode;
        } else {
            company_address.line1 = this.account.BillingStreet;
            company_address.city = this.account.BillingCity;
            company_address.state = this.account.BillingState;
            company_address.postal_code = this.account.BillingPostalCode;
            company_address.country = this.account.BillingCountryCode;
        }
        req.company_address = company_address;        
        CDdRestJSONObj.RestAPIResponse accountTokenRes = connector.invokeRESTAPI(
                                                            'POST'
                                                            , req.getURLEncoded()
                                                            , getStripeAuthPubKey(this.account.BillingCountryCode)
                                                            , CDdNimdaSyncConstants.CREATE_STRIPE_BANK_TOKEN_ENDPOINT
                                                            , ''
                                                            , 'application/x-www-form-urlencoded');
        CDdRestJSONObj.StripeAccountTokenResponse response = (CDdRestJSONObj.StripeAccountTokenResponse) JSON.deserialize(accountTokenRes.body, CDdRestJSONObj.StripeAccountTokenResponse.class);
        // Check for response errors            
        if (response.error != null) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , response.error.getFormattedError()
                                            , JSON.serialize(req)
                                            , JSON.serialize(response)
                                        );              
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, JSON.serialize(req), JSON.serialize(response));         
    }
    /**
    * @description An operation that interacts with Stripe API to create a Stripe Account Token
    * REST Endpoint referenced is 'https://api.stripe.com/v1/tokens'
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with Stripe API
    **/             
    public CDdNimdaSyncInfo createStripePersonToken() {
        CDdRestJSONObj.StripePersonTokenRequest req = new CDdRestJSONObj.StripePersonTokenRequest();
        Contact stripeAccountOwner = this.opportunity.Stripe_Account_Owner__r;
        req.individual_first_name = stripeAccountOwner.FirstName;
        req.individual_last_name = stripeAccountOwner.LastName;
        if (stripeAccountOwner.Birthdate!=null){
            CDdRestJSONObj.DOB individual_date_of_birth = new CDdRestJSONObj.DOB();
            individual_date_of_birth.month = String.valueOf(stripeAccountOwner.Birthdate.month()).leftPad(2, '0');
            individual_date_of_birth.day = String.valueOf(stripeAccountOwner.Birthdate.day()).leftPad(2, '0');
            individual_date_of_birth.year = String.valueOf(stripeAccountOwner.Birthdate.year());
            req.individual_date_of_birth = individual_date_of_birth;
        }
        if (stripeAccountOwner.MailingStreet!=null 
                        && stripeAccountOwner.MailingCity!=null
                        && stripeAccountOwner.MailingState!=null
                        && stripeAccountOwner.MailingPostalCode!=null
                        && stripeAccountOwner.MailingCountryCode!=null){
            CDdRestJSONObj.Address individual_address = new CDdRestJSONObj.Address();
            individual_address.line1 = stripeAccountOwner.MailingStreet;
            individual_address.city = stripeAccountOwner.MailingCity;
            individual_address.state = stripeAccountOwner.MailingState;
            individual_address.postal_code = stripeAccountOwner.MailingPostalCode;
            individual_address.country = stripeAccountOwner.MailingCountryCode;
            req.individual_address = individual_address;
        } 
        req.individual_id_number = getIndividualIdNumber();
        req.individual_relationship_executive = true;
        req.individual_relationship_representative = true;
        CDdRestJSONObj.RestAPIResponse personTokenRes = connector.invokeRESTAPI(
                                                            'POST'
                                                            , req.getURLEncoded()
                                                            , getStripeAuthPubKey(this.account.BillingCountryCode)
                                                            , CDdNimdaSyncConstants.CREATE_STRIPE_BANK_TOKEN_ENDPOINT
                                                            , ''
                                                            , 'application/x-www-form-urlencoded');
        CDdRestJSONObj.StripePersonTokenResponse response = (CDdRestJSONObj.StripePersonTokenResponse) JSON.deserialize(personTokenRes.body, CDdRestJSONObj.StripePersonTokenResponse.class);
        // Check for response errors            
        if (response.error != null) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , response.error.getFormattedError()
                                            , JSON.serialize(req)
                                            , JSON.serialize(response)
                                        );              
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, JSON.serialize(req), JSON.serialize(response));         
    }                
    /**
    * @description An operation that interacts with the DoorDash Payments Account API to create a Payment Account using Account Token only
    * REST Endpoint referenced is '/v1/payment_accounts'
    * @param String input Stripe Account Token
    * @param String input Stripe Person Token      
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createPaymentAccount(String stripeAccountToken, String stripePersonToken) {
        if (String.isBlank(this.storeId)){
            throw new CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, CDdNimdaSyncConstants.ERROR_MSG_INVALID_STORE_ID);                  
        }
        if (String.isBlank(stripeAccountToken) || String.isBlank(stripePersonToken)){
            throw new CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, String.isBlank(stripeAccountToken) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_ACCOUNT_TOKEN_ID : CDdNimdaSyncConstants.ERROR_MSG_INVALID_PERSON_TOKEN_ID);                  
        }
        CDdRestJSONObj.DoorstepPaymentAccountRequest paymentAcctReq = new CDdRestJSONObj.DoorstepPaymentAccountRequest();
        paymentAcctReq.target_type = 'store';
        paymentAcctReq.target_id = this.storeId;
        paymentAcctReq.account_token = stripeAccountToken;
        paymentAcctReq.person_token = stripePersonToken;
        
        CDdRestJSONObj.RestAPIResponse paymentAcctRes = connector.postDoorstep(JSON.serialize(paymentAcctReq, true), '/v1/payment_accounts');
        System.debug(paymentAcctRes.body);
        if (paymentAcctRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, JSON.serialize(paymentAcctReq, true), paymentAcctRes.body);
        }        
        CDdRestJSONObj.DoorstepPaymentAccountResponse paymentAcct = (CDdRestJSONObj.DoorstepPaymentAccountResponse) JSON.deserialize(paymentAcctRes.body, CDdRestJSONObj.DoorstepPaymentAccountResponse.class);
        // Check for response errors
        if (String.isNotBlank(paymentAcct.detail)
                || String.isNotBlank(paymentAcct.non_field_errors)
                || (paymentAcct.stripe_account_id == null)     
            ) {
            String responseError =  String.isNotBlank(paymentAcct.detail) 
                                    ?   paymentAcct.detail 
                                    :   (String.isNotBlank(paymentAcct.non_field_errors) 
                                            ?   paymentAcct.non_field_errors 
                                            :   ( (paymentAcct.stripe_account_id == null) ? paymentAcctRes.body : '') 
                                        );
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , responseError
                                            , JSON.serialize(paymentAcctReq)
                                            , JSON.serialize(paymentAcct)
                                        );               
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, JSON.serialize(paymentAcctReq), JSON.serialize(paymentAcct));               
    }         
    /**
    * @description An operation that interacts with the external service to create a Stripe Bank Token
    * REST Endpoint referenced is 'https://api.stripe.com/v1/tokens'
    * Note : This service references the new data points on the Account object for Payment Account information
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createStripeBankToken() {
        List<String> errorMessages = validator.fieldValidator(this.account, CDdNimdaSyncConstants.VALIDATE_PAYMENT_ACCOUNT_FIELDS_ON_ACCOUNT);
        if (!errorMessages.isEmpty()){
            throw new CDdNimdaSyncServiceException(CDdNimdaSyncConstants.STEP_PAYMENT_ACCOUNT, CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION, String.join(errorMessages, ','));               
        }         
        CDdRestJSONObj.StripeBankTokenRequest bankTokenReq = new CDdRestJSONObj.StripeBankTokenRequest();
        bankTokenReq.country = this.account.BillingCountryCode;
        bankTokenReq.curr = getCurrency();
        bankTokenReq.account_holder_name = EncodingUtil.urlEncode(this.account.Legal_Business_Name__c, 'UTF-8');
        bankTokenReq.account_holder_type = 'company';
        bankTokenReq.account_number = this.account.Bank_Account_Number_Encrypted__c;
        bankTokenReq.routing_number = this.account.Bank_Routing_Number_Encrypted__c.trim() 
                                        + (('CA'.equals(this.account.BillingCountryCode) && String.isNotBlank(this.account.Bank_Institution_Number_Encrypted__c)) ? this.account.Bank_Institution_Number_Encrypted__c.trim() : '');
        
        //I need to remove the trailing slash, or Stripe API will complain. 
        //Also, they require urlencoded form for input, hence the custom function call
        CDdRestJSONObj.RestAPIResponse bankTokenRes = connector.invokeRESTAPI(
                                                            'POST'
                                                            , bankTokenReq.getURLEncoded()
                                                            , getStripeAuthPubKey(this.account.BillingCountryCode)
                                                            , CDdNimdaSyncConstants.CREATE_STRIPE_BANK_TOKEN_ENDPOINT
                                                            , ''
                                                            , 'application/x-www-form-urlencoded');
        CDdRestJSONObj.StripeBankTokenResponse bankToken = (CDdRestJSONObj.StripeBankTokenResponse) JSON.deserialize(bankTokenRes.body, CDdRestJSONObj.StripeBankTokenResponse.class);
        // Check for response errors            
        if (bankToken.error != null) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , bankToken.error.getFormattedError()
                                            , JSON.serialize(bankTokenReq)
                                            , JSON.serialize(bankToken)
                                        );              
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_STRIPE_BANK_TOKEN, JSON.serialize(bankTokenReq), JSON.serialize(bankToken));         
    }    
    /**
    * @description An operation that interacts with the external service to create a Stripe Bank Account
    * REST Endpoint referenced is 'https://api.stripe.com/v1/accounts/{stripe_account_id}/external_accounts'
    * @param String input Stripe Account Id
    * @param String input Bank Token Id     
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createStripeBankAccount(String stripeAcctId, String bankTokenId) {
        // check for validation errors
        Boolean hasValidationError = String.isBlank(stripeAcctId) || String.isBlank(bankTokenId);
        String validationError = hasValidationError ? ( String.isBlank(stripeAcctId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_STRIPE_ACCOUNT_ID : (String.isBlank(bankTokenId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_BANK_TOKEN_ID : '')) : '';                
        if (hasValidationError){
            throw new CDdNimdaSyncServiceException(
                                        CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , validationError
                                    );                  
        }
        CDdRestJSONObj.StripeExternalAccountRequest externalAcctReq = new CDdRestJSONObj.StripeExternalAccountRequest();
        externalAcctReq.external_account = bankTokenId;
        CDdRestJSONObj.RestAPIResponse externalAcctRes = connector.invokeRESTAPI(
                                                            'POST'
                                                            , externalAcctReq.getURLEncoded()
                                                            , getStripeAuth(this.account.BillingCountryCode)
                                                            , String.format(CDdNimdaSyncConstants.CREATE_STRIPE_BANK_ACCOUNT_ENDPOINT, new List<String>{stripeAcctId})
                                                            , CDdNimdaSyncConstants.CREATE_STRIPE_BANK_ACCOUNT_ENDPOINT_SUFFIX
                                                            , 'application/x-www-form-urlencoded');
        CDdRestJSONObj.StripeExternalAccountResponse externalAcct = (CDdRestJSONObj.StripeExternalAccountResponse) JSON.deserialize(externalAcctRes.body, CDdRestJSONObj.StripeExternalAccountResponse.class);
        // Check for response errors            
        if (externalAcct.error != null) {
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , externalAcct.error.getFormattedError()
                                            , JSON.serialize(externalAcctReq)
                                            , JSON.serialize(externalAcct)
                                        );
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, JSON.serialize(externalAcctReq), JSON.serialize(externalAcct));
    }
    /**
    * @description An operation that interacts with the DSJ service for creating a Bank Account
    * REST Endpoint referenced is '/v1/payment_accounts/{payment_account_id}/bank_accounts'
    * @param String input Payment Account Id
    * @param String input Bank Token Id     
    * @return CDdNimdaSyncInfo the sync info object that includes the request and response information on interaction with external service
    **/             
    public CDdNimdaSyncInfo createDSJBankAccount(String paymentAcctId, String bankTokenId) {
        // check for validation errors
        Boolean hasValidationError = String.isBlank(paymentAcctId) || String.isBlank(bankTokenId);
        String validationError = hasValidationError ? ( String.isBlank(paymentAcctId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_PAYMENT_ACCOUNT_ID : (String.isBlank(bankTokenId) ? CDdNimdaSyncConstants.ERROR_MSG_INVALID_BANK_TOKEN_ID : '')) : '';                
        if (hasValidationError){
            throw new CDdNimdaSyncServiceException(
                                        CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT
                                        , CDdNimdaSyncConstants.ERROR_TYPE_VALIDATION
                                        , validationError
                                    );                  
        }
        CDdRestJSONObj.DoorstepBankAccountRequest bankAcctReq = new CDdRestJSONObj.DoorstepBankAccountRequest();
        bankAcctReq.stripe_token = bankTokenId;
        
        CDdRestJSONObj.RestAPIResponse bankAcctRes = connector.postDoorstep(JSON.serialize(bankAcctReq, true), '/v1/payment_accounts/' + paymentAcctId + '/bank_accounts');
        System.debug(bankAcctRes.body);
        if (bankAcctRes.statusCode == 500){
            handleResponseCode500(CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, JSON.serialize(bankAcctReq, true), bankAcctRes.body);
        }        
        CDdRestJSONObj.DoorstepBankAccountResponse bankAcct = (CDdRestJSONObj.DoorstepBankAccountResponse) JSON.deserialize(bankAcctRes.body, CDdRestJSONObj.DoorstepBankAccountResponse.class);
        // Check for response errors
        if (String.isNotBlank(bankAcct.detail)
                || String.isNotBlank(bankAcct.non_field_errors)
                || (bankAcct.id == null)     
            ) {
            String responseError =  String.isNotBlank(bankAcct.detail) 
                                    ?   bankAcct.detail 
                                    :   (String.isNotBlank(bankAcct.non_field_errors) 
                                            ?   bankAcct.non_field_errors 
                                            :   ( (bankAcct.id == null) ? bankAcctRes.body : '') 
                                        );
            throw new CDdNimdaSyncServiceException(
                                            CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT
                                            , CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE
                                            , responseError
                                            , JSON.serialize(bankAcctReq)
                                            , JSON.serialize(bankAcct)
                                        );               
        }
        // Create CDdNimdaSyncInfo Object and return to the caller
        return new CDdNimdaSyncInfo(CDdNimdaSyncConstants.STEP_STRIPE_BANK_ACCOUNT, JSON.serialize(bankAcctReq), JSON.serialize(bankAcct));
    }                           
    /**
    * @description Get the Stripe Auth Secret Key
    * @param String input Country Code  
    * @return String return the Bearer Authentication string for secret key
    **/
    public String getStripeAuth(String countryCode){
        String retVal = CDdNimdaSyncConstants.AUTHORIZATION_BEARER;
        if ('CA'.equals(countryCode)){
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token_CA__c : apiSettings.Stripe_API_Token_CA__c);
        } else if ('AU'.equals(countryCode)){
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token_AUS__c : apiSettings.Stripe_API_Token_AUS__c);
        } else {
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token__c : apiSettings.Stripe_API_Token__c);
        }
    }
    /**
    * @description Get the Stripe Auth Published Key
    * @param String input Country Code     
    * @return String return the Bearer Authentication string for published key
    **/
    public String getStripeAuthPubKey(String countryCode){
        String retVal = CDdNimdaSyncConstants.AUTHORIZATION_BEARER;
        if ('CA'.equals(countryCode)){
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token_PK_CA__c : apiSettings.Stripe_API_Token_PK_CA__c);
        } else if ('AU'.equals(countryCode)){
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token_PK_AUS__c : apiSettings.Stripe_API_Token_PK_AUS__c);
        } else {
            return retVal + (apiSettings.UseStripeSandbox__c ? apiSettings.Stripe_Sandbox_API_Token_PK__c : apiSettings.Stripe_API_Token_PK__c);
        }
    }    
    /**
    * @description Get the currency based on billing country code
    * @return String return the Currency string
    **/    
    public String getCurrency(){
                return (this.account!=null && String.isNotBlank(this.account.BillingCountryCode))
                ?   (this.account.BillingCountryCode.equals('CA') ? 'cad' : (this.account.BillingCountryCode.equals('AU') ? 'aud' : 'usd'))
                :   'usd';
    }
    /**
    * @description Get the individual Id number
    * @return String return the individual Id Number
    **/    
    public String getIndividualIdNumber(){
        switch on this.account.BillingCountryCode {
            when 'AU' {
                return CDdNimdaSyncConstants.ENABLE_S2N_AU_INDIVIDUAL_ID_NUMBER ? this.account.EIN_Encrypted__c : '';
            }
            when 'CA' {
                return CDdNimdaSyncConstants.ENABLE_S2N_CA_INDIVIDUAL_ID_NUMBER ? this.account.EIN_Encrypted__c : '';
            }
            when 'US' {
                return CDdNimdaSyncConstants.ENABLE_S2N_US_INDIVIDUAL_ID_NUMBER ? this.account.EIN_Encrypted__c : '';
            }
            when else {
                return '';
            }                                    
        }
    }    
    /**
    * @description Handle response code 500
    * @return 
    **/    
    public void handleResponseCode500(String step, String request, String responseBody){
        String errorMessage = '500 Internal Server Error. ';
        Integer index = responseBody.indexOf('reference id: ');
        if (index > -1){
            errorMessage += 'Reference Id: ' + responseBody.substring(index+14, index+14+32);
        }
        throw new CDdNimdaSyncServiceException(step, CDdNimdaSyncConstants.ERROR_TYPE_RESPONSE, errorMessage, request, errorMessage);         
    }
    /**
    * @description Inner class used for interaction with the caller of this service
    * This object includes the request and response information produced during the invocation of the external REST service
    **/ 
    public class CDdNimdaSyncInfo {
        /**
        * @description What step did the error take place in?
        * - Create Store
        * - Create User
        * - Create Merchant
        * - Payment Account
        * - Stripe Bank Token
        * - Stripe Bank Account
        **/     
        @AuraEnabled
        public String step {get; set;}
        /**
        * @description The serialized callout request
        **/                     
        @AuraEnabled
        public String calloutRequest {get; set;}
        /**
        * @description The serialized callout response
        **/                     
        @AuraEnabled
        public String calloutResponse {get; set;}
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/     
        public CDdNimdaSyncInfo(String step, String calloutRequest, String calloutResponse){
            this.step = step;
            this.calloutRequest = calloutRequest;
            this.calloutResponse = calloutResponse;
        }               
    }
   /**
    * @description Inner class used for capturing the exception data
    **/ 
    public class CDdNimdaSyncExceptionData {
        /**
        * @description What step did the error take place in?
        * - Create Store
        * - Create User
        * - Create Merchant
        * - Payment Account
        * - Stripe Bank Token
        * - Stripe Bank Account
        **/     
        public String step;
        /**
        * @description The serialized callout request
        **/                     
        public String calloutRequest;
        /**
        * @description The serialized callout response
        **/                     
        public String calloutResponse;
        /**
        * @description What is the error type? Error types are 'Validation Error', 'Response Error', 'Runtime Exception' 
        **/     
        public String errorType;
        /**
        * @description The actual error message
        **/         
        public String errorMessage; 
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        **/     
        public CDdNimdaSyncExceptionData(String step, String errorType, String errorMessage){
            this.step = step;
            this.errorType = errorType;
            this.errorMessage = errorMessage;
            this.calloutRequest = null;
            this.calloutResponse = null;            
        }       
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/     
        public CDdNimdaSyncExceptionData(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
            this(step, errorType, errorMessage);
            this.calloutRequest = calloutRequest;
            this.calloutResponse = calloutResponse;
        }
    }
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/     
    public class CDdNimdaSyncServiceException extends Exception {
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        **/     
        public CDdNimdaSyncServiceException(String step, String errorType, String errorMessage){
            setMessage(JSON.serialize(new CDdNimdaSyncExceptionData(step, errorType, errorMessage), true));
        }       
        /**
        * @description Constructor - instantiate the exception with the following parameters
        * @param String the Step in execution
        * @param String the Error Type  
        * @param String the Error Message
        * @param String the Callout Request
        * @param String the Callout Response
        **/     
        public CDdNimdaSyncServiceException(String step, String errorType, String errorMessage, String calloutRequest, String calloutResponse){
            setMessage(JSON.serialize(new CDdNimdaSyncExceptionData(step, errorType, errorMessage, calloutRequest, calloutResponse), true));
        }
    }   
}