/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 04/16/2019
*
* @group Nimda
*
* @description This is the Lightning Controller for Nimda Sync 
* Purpose of this controller is to
* - Communicate with Lightning Component LDdNimdaSync for asynchronous operations that includes callouts to external system
* - Perform SOQL Query and DML operations on Account and Opportunity object related to Nimda Sync data points
* - Interact via the CDdNimdaSyncService with external interfaces namely DSJ, Nimda and Stripe
* 
**************************************************************************************************************************************/
public class CDdLtngNimdaSyncCtrl {
    /**
    * @description Get Account record
    * @param Id accountId
    * @return Account record
    **/
    @AuraEnabled(cacheable=true)
    public static Account getAccount(Id accountId) {
        try {
            if (String.isBlank(accountId)){
                throw new CDdLtngNimdaSyncCtrlException(CDdNimdaSyncConstants.ERROR_MSG_INVALID_ACCOUNT_ID); 
            }
            Account account = null;
            for (Account a :    [SELECT 
                                Id, Name, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingCountry, BillingCountryCode
                                , BillingLatitude, BillingLongitude, Business_Id__c, Commission__c, Converted_Lead_ID__c
                                , Parent.Business_ID__c, Phone, Price_Range_S2N__c, RealZip_Submarket_Id__c
                                , Legal_Business_Name__c, Bank_Account_Number_Encrypted__c, Bank_Routing_Number_Encrypted__c, Bank_Institution_Number_Encrypted__c, EIN_Encrypted__c
                                , ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode
                                , Restaurant_ID__c, Merchant_Supplied_ID__c, Payment_Account_ID__c, Formstack_Version__c
                                , Fulfills_Own_Deliveries_Disabled__c, Is_Test_Store__c, Portal_User_Id__c
                                FROM Account 
                                WHERE Id = :accountId]){
                account = a;
            }
            return account; 
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Account Id : ' + accountId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }              
    }   
    /**
    * @description Get Opportunity record
    * @param Id opportunityId
    * @return Opportunity record
    **/
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(Id opportunityId) {
        try {
            if (String.isBlank(opportunityId)){
                throw new CDdLtngNimdaSyncCtrlException(CDdNimdaSyncConstants.ERROR_MSG_INVALID_OPPORTUNITY_ID); 
            }      
            Opportunity opportunity = null;
            for (Opportunity o :    [SELECT 
                                    Name, RecordTypeId, Business_Id__c, Store_ID__c, AccountId, Account.BillingStreet, 
                                    Account.BillingState, Account.BillingLatitude, Account.BillingLongitude, Account.Phone,
                                    Account.BillingCity, Account.BillingPostalCode, Account.BillingCountry, Account.BillingCountryCode,
                                    Account.RealZip_Submarket_Id__c, Starting_Point_ID__c, StageName, DM_Email__c, Order_Protocol__c, Type, Trial_Type__c, Trial_End_Date__c,
                                    Pricing_Tier_New__c, Trial_Pricing_Tier__c, Menu_URL__c, Commission__c, 
                                    Stripe_Bank_Account__c, Stripe_Account__c, POS_Integration_ID__c, 
                                    POS_Integration_Type__c, Merchant_Agreed_to__c, Service_Fee_New__c, Trial_Service_Fee__c, Order_Service_Type__c, Order_Protocol_Email__c, Order_Protocol_Fax__c,
                                    Maximum_Order_Size__c, Tax_Override_Rate__c, In_App_Pickup_Commission__c, Weekly_Tablet_Subscription_Fee__c, Weekly_Printer_Subscription_Fee__c,
                                    DashPass_Only_Commission__c, Activation_Fee__c, Trial_Commission__c, CreatedById, Stripe_Account_Owner__c,
                                    Stripe_Account_Owner__r.FirstName, Stripe_Account_Owner__r.LastName, Stripe_Account_Owner__r.Birthdate,
                                    Stripe_Account_Owner__r.MailingStreet, Stripe_Account_Owner__r.MailingCity, Stripe_Account_Owner__r.MailingState,
                                    Stripe_Account_Owner__r.MailingPostalCode, Stripe_Account_Owner__r.MailingCountry, Stripe_Account_Owner__r.MailingCountryCode,
                                    Account.Legal_Business_Name__c, Account.Bank_Account_Number_Encrypted__c, Account.Bank_Routing_Number_Encrypted__c, Account.EIN_Encrypted__c,
                                    Custom_Delivery_Radius__c, Fulfills_Own_Deliveries__c, Delivery_Fee__c, DashPass_Eligible_CW__c, Inflation__c, Inflation_Rounding_Unit__c,
                                    Referred_Pickup_Commission__c, Referred_Delivery_Commission__c,
                                    Decision_Maker__c, DashPass_Flat_Fee__c, Max_Delivery_radius_KM__c, Platform__c,
                                    Change_of_Ownership_Effective_Date__c, Original_Store_ID__c, Account.Name, Account.Restaurant_ID__c, Change_of_Ownership_Business_Id__c,
                                    Change_of_Ownership_Business_Option__c, Account.Parent.Business_ID__c, Shopping_Protocol__c, AOR_Distance__c, AOR_Enabled__c, Proposed_Date_of_Menu__c                                                                
            FROM Opportunity 
            WHERE Id = :opportunityId]){
                opportunity = o;
            }
            if (opportunity!=null && !(new CDdNimdaSyncValidator(null, opportunity).isOpportunityStageClosedWon())){
                throw new CDdLtngNimdaSyncCtrlException(CDdNimdaSyncConstants.ERROR_MSG_OPPORTUNITY_NOT_CLOSED_WON);
            }
            // Validation error for COO opportunities
            if (opportunity != null) {
                List<String> errorMessages = new CDdNimdaSyncValidator(null, opportunity).validateForChangeOfOwnership();
                if (!errorMessages.isEmpty()){
                    throw new CDdLtngNimdaSyncCtrlException(String.join(errorMessages, ', '));
                }    
            }             
            return opportunity; 
        } catch (Exception ex){
            CDdErrorUtilities.publishException('Opportunity','CDdLtngNimdaSyncCtrl-getOpportunity', opportunityId, ex);
            throw new AuraHandledException(ex.getMessage());
        }              
    }
    /**
    * @description Get Addresses
    * @param Account input account record   
    * @return List<CDdRestJSONObj.Address> Collection of Address objects
    **/
    @AuraEnabled
    public static Object getAddresses(Account account) {
        try {
            return JSON.serialize(new CDdNimdaSyncSearchStoreService(account).getAddresses());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get addresses: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Account Id : ' + account.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getAddresses', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get Stores
    * @param String input Business Id
    * @param String input Address Id        
    * @param Account input account record   
    * @return List<CDdRestJSONObj.StoreSuccesses> Collection of Store objects
    **/
    @AuraEnabled
    public static Object getStores(String businessId, String addressId, Account account) {
        try {
            return JSON.serialize(new CDdNimdaSyncSearchStoreService(businessId, addressId, account).getStores());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get stores: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Account Id : ' + account.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStores', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get All Stores for the input Business Id and the Address on the input Account
    * @param String input Business Id    
    * @param Account input account record   
    * @return List<CDdRestJSONObj.StoreSuccesses> Collection of Store objects
    **/
    @AuraEnabled
    public static Object getAllStores(String businessId, Account account) {
        try {
            List<CDdRestJSONObj.StoreSuccesses> stores = new List<CDdRestJSONObj.StoreSuccesses>();
            List<CDdRestJSONObj.Address> addresses = new CDdNimdaSyncSearchStoreService(account).getAddresses();
            for (CDdRestJSONObj.Address address : addresses){
                stores.addAll(new CDdNimdaSyncSearchStoreService(businessId, String.valueOf(address.id), account).getStores());
            }
            return JSON.serialize(stores);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get all stores: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Account Id : ' + account.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getAllStores', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get Nimda Store field definitions from custom metadata
    * @return Serialized store field definitions
    **/
    @AuraEnabled
    public static Object getNimdaStoreFieldDefinitions() {
        return JSON.serialize(CDdNimdaSyncStoreHelper.getNimdaStoreFieldDefinitions());
    }    
    /**
    * @description Get store detail for the input Store Id
    * @param String input Store Id    
    * @return Serialized store detail record from Nimda backend
    **/
    @AuraEnabled
    public static Object getStore(String storeId) {
        try {
            return new CDdNimdaSyncSearchStoreService().getStore(storeId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get store partnership info for the input Store Id
    * @param String input Store Id    
    * @return Serialized store partnership info from Nimda backend
    **/
    @AuraEnabled
    public static Object getStorePartnership(String storeId) {
        try {
            return new CDdNimdaSyncSearchStoreService().getStorePartnership(storeId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store partnership: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStorePartnership', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Get store point of sale info for the input Store Id
    * @param String input Store Id    
    * @return Serialized store point of sale info from Nimda backend
    **/
    @AuraEnabled
    public static Object getStorePOS(String storeId) {
        try {
            return new CDdNimdaSyncSearchStoreService().getStorePOS(storeId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store point of sale: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStorePOS', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }    
    /**
    * @description Get payment account info for the input Payment Account Id
    * @param String input Payment Account Id    
    * @return Serialized Payment Account info from Nimda backend
    **/
    @AuraEnabled
    public static Object getPaymentAccount(String paymentAccountId) {
        try {
            return new CDdNimdaSyncSearchStoreService().getPaymentAccount(paymentAccountId);
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get payment account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Payment Account Id : ' + paymentAccountId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getPaymentAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }    
    /**
    * @description Get store request for update purpose
    * @param String input Business Id   
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return the store request object <CDdRestJSONObj.DoorstepStoreRequest>
    **/
    @AuraEnabled
    public static Object getStoreRequest(String businessId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(CDdNimdaSyncStoreHelper.getStoreRequest(CDdNimdaSyncConstants.STEP_UPDATE_STORE, businessId, account, opportunity));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to get store request object: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'getStoreRequest', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }                     
    /**
    * @description Create store
    * @param String input Business Id   
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createStore(String businessId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, account, opportunity).createStore());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create store: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Update Store and/or Store Partnership record
    * Note: If a store partnership property needs to be updated, you must send along with the changes, the non-null values
    * of the current store partnership record, to ensure the new Store Partnership record in Nimda is stamped with
    * updated and carryover values from previous version
    * @param String The Store Id to update
    * @param String storeRequest [A JSON string with the specific store and/or store partnership properties and values]  
    * @return Return the Store POST response information on interaction with external service
    **/
    @AuraEnabled             
    public static Object updateStore(String storeId, String storeRequest) {
        try {
            return JSON.serialize(new CDdNimdaSyncSearchStoreService().updateStore(storeId, storeRequest));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update store: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'updateStore', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Update Store Point of Sale record
    * @param String The Store Id to update
    * @param String storeRequest [A JSON string with the specific store property and value for Provider Type, Location Id]   
    * @return Return the Store Point of Sale PUT response information on interaction with external service
    **/
    @AuraEnabled             
    public static Object updateStorePOS(String storeId, String storeRequest) {
        try {
            return JSON.serialize(new CDdNimdaSyncSearchStoreService().updateStorePOS(storeId, storeRequest));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update store point of sale: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Store Id : ' + storeId + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'updateStorePOS', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }            
    /**
    * @description Create User
    * @param String input Business Id
    * @param String input Store Id          
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createUser(String businessId, String storeId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, storeId, account, opportunity).createUser());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create user: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createUser', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Create Merchant
    * @param String input Business Id
    * @param String input Store Id
    * @param String input User Id               
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createMerchant(String businessId, String storeId, String userId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, storeId, userId, account, opportunity).createMerchant());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create merchant: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createMerchant', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Create Payment Account
    * @param String input Business Id
    * @param String input Store Id          
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createPaymentAccount(String businessId, String storeId, Account account, Opportunity opportunity) {
        try {
            CDdNimdaSyncService service = new CDdNimdaSyncService(businessId, storeId, account, opportunity);
            service.stripeTokenValidation();
            CDdRestJSONObj.StripeAccountTokenResponse stripeAccountTokenResponse 
                        = (CDdRestJSONObj.StripeAccountTokenResponse) JSON.deserialize(
                            service.createStripeAccountToken().calloutResponse, 
                            CDdRestJSONObj.StripeAccountTokenResponse.class);
            CDdRestJSONObj.StripePersonTokenResponse stripePersonTokenResponse 
                        = (CDdRestJSONObj.StripePersonTokenResponse) JSON.deserialize(
                            service.createStripePersonToken().calloutResponse, 
                            CDdRestJSONObj.StripePersonTokenResponse.class);                        
            return JSON.serialize(service.createPaymentAccount(stripeAccountTokenResponse.id, stripePersonTokenResponse.id)); 
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create payment account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createPaymentAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Create Stripe Bank Token
    * @param String input Business Id
    * @param String input Stripe Account Id         
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createStripeBankToken(String businessId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, account, opportunity).createStripeBankToken());
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create stripe bank token: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createStripeBankToken', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Create Stripe Bank Token
    * @param String input Business Id
    * @param String input Stripe Account Id
    * @param String input Bank Token Id             
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createStripeBankAccount(String businessId, String stripeAcctId, String bankTokenId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, account, opportunity).createStripeBankAccount(stripeAcctId, bankTokenId));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create stripe bank account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createStripeBankAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    /**
    * @description Create external account using the DSJ Payment Bank Account API
    * @param String input Business Id
    * @param String input Payment Account Id
    * @param String input Bank Token Id             
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @return <CDdNimdaSyncService.CDdNimdaSyncInfo> sync info object
    **/
    @AuraEnabled
    public static Object createDSJBankAccount(String businessId, String paymentAcctId, String bankTokenId, Account account, Opportunity opportunity) {
        try {
            return JSON.serialize(new CDdNimdaSyncService(businessId, account, opportunity).createDSJBankAccount(paymentAcctId, bankTokenId));
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to create DSJ bank account: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'createDSJBankAccount', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }    
    }    
    /**
    * @description Apply updates to Account and Opportunity record
    * @param String input Business Id
    * @param String input Store Id     
    * @param String input Stripe Account Id
    * @param String input Stripe Bank Account Id        
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @param Exception data - serialized string with info - Error Step, Type, Message, Callout Request and Callout Response    
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean applyUpdates(String businessId, String storeId, String userId, String paymentAcctId, String stripeAcctId, String stripeBankAcctId, Account account, Opportunity opportunity, String exceptionDataStr) {
        try {
            // Update Account
            Account acctToUpdate = new Account ( Id = account.Id );
            Boolean updateAcct = false;
            if (String.isNotBlank(businessId)) {
                acctToUpdate.Business_ID__c = Integer.valueOf(businessId);
                acctToUpdate.isMaster__c = true;
                updateAcct = true;
            }
            if (String.isNotBlank(storeId)) {
                acctToUpdate.Restaurant_Id__c = CDdStringUtil.stripDecimal(Decimal.valueOf(storeId));
                updateAcct = true;
            }
            if (String.isBlank(account.Portal_User_Id__c) && String.isNotBlank(userId)) {
                acctToUpdate.Portal_User_Id__c = userId;
                updateAcct = true;
            }            
            if (String.isBlank(account.Payment_Account_ID__c) && String.isNotBlank(paymentAcctId)) {
                acctToUpdate.Payment_Account_ID__c = paymentAcctId;
                updateAcct = true;
            }            
            if (updateAcct){
                update acctToUpdate;
            }
            // Update Opportunity
            Opportunity oppToUpdate = new Opportunity ( Id = opportunity.Id );
            Boolean updateOpp = false;                    
            if (String.isNotBlank(businessId)) {
                oppToUpdate.Business_ID__c = Integer.valueOf(businessId);
                updateOpp = true;
            }
            if (String.isBlank(opportunity.Stripe_Account__c) && String.isNotBlank(stripeAcctId)) {
                oppToUpdate.Stripe_Account__c = stripeAcctId;
                updateOpp = true;
            }
            if (String.isBlank(opportunity.Stripe_Bank_Account__c) && String.isNotBlank(stripeBankAcctId)){
                oppToUpdate.Stripe_Bank_Account__c = stripeBankAcctId;
                updateOpp = true;
            }
            if (String.isNotBlank(exceptionDataStr)){
                Map<String, Object> exceptionData = (Map<String, Object>)JSON.deserializeUntyped(exceptionDataStr);
                if (exceptionData.containsKey('step')){
                    oppToUpdate.Nimda_Sync_Step__c = (String)exceptionData.get('step');
                    if (CDdNimdaSyncConstants.STEP_COMPLETE.equals((String)exceptionData.get('step'))){
                        oppToUpdate.Nimda_Sync_Error_Type__c = null;
                        oppToUpdate.Nimda_Sync_Error_Message__c = null;
                        oppToUpdate.Nimda_Sync_Callout_Request__c = null;
                        oppToUpdate.Nimda_Sync_Callout_Response__c = null;
                    }
                    updateOpp = true;
                }
                if (exceptionData.containsKey('errorType')){
                    oppToUpdate.Nimda_Sync_Error_Type__c = (String)exceptionData.get('errorType');
                    updateOpp = true;
                }
                if (exceptionData.containsKey('errorMessage')){
                    oppToUpdate.Nimda_Sync_Error_Message__c = (String)exceptionData.get('errorMessage');
                    updateOpp = true;
                }
                if (exceptionData.containsKey('calloutRequest')){
                    oppToUpdate.Nimda_Sync_Callout_Request__c = (String)exceptionData.get('calloutRequest');
                    updateOpp = true;
                }
                if (exceptionData.containsKey('calloutResponse')){
                    oppToUpdate.Nimda_Sync_Callout_Response__c = (String)exceptionData.get('calloutResponse');
                    updateOpp = true;
                }                                                     
            }
            if (updateOpp){
                update oppToUpdate;
            }
            return true;    
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to apply updates: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'applyUpdates', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Apply updates to Account and Opportunity record from STN v3 Payment Component
    * @param String input paymentAcctId   
    * @param String input Stripe Account Id
    * @param String input Stripe Bank Account Id        
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @param Exception data - serialized string with info - Error Step, Type, Message, Callout Request and Callout Response    
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean applyPaymentV3Updates(String paymentAcctId, String stripeAcctId, String stripeBankAcctId, Account account, Opportunity opportunity, String exceptionDataStr) {
        try {
            // Update Account
            Account acctToUpdate = new Account ( Id = account.Id );
            Boolean updateAcct = false;
            if (String.isNotBlank(paymentAcctId) && String.isNotBlank(stripeAcctId)
                    && (String.isBlank(account.Payment_Account_ID__c) || (!paymentAcctId.equals(account.Payment_Account_ID__c)))) {
                acctToUpdate.Payment_Account_ID__c = paymentAcctId;
                updateAcct = true;
            }            
            if (updateAcct){
                update acctToUpdate;
            }
            // Update Opportunity
            Opportunity oppToUpdate = new Opportunity ( Id = opportunity.Id );
            Boolean updateOpp = false;                    
            if (String.isNotBlank(stripeAcctId)
                && (String.isBlank(opportunity.Stripe_Account__c) || (!stripeAcctId.equals(opportunity.Stripe_Account__c)))) {            
                oppToUpdate.Stripe_Account__c = stripeAcctId;
                updateOpp = true;
            }
            if (String.isNotBlank(stripeBankAcctId)
                && (String.isBlank(opportunity.Stripe_Bank_Account__c) || (!stripeBankAcctId.equals(opportunity.Stripe_Bank_Account__c)))) {
                oppToUpdate.Stripe_Bank_Account__c = stripeBankAcctId;
                updateOpp = true;
            }
            if (String.isNotBlank(exceptionDataStr)){
                Map<String, Object> exceptionData = (Map<String, Object>)JSON.deserializeUntyped(exceptionDataStr);
                String paymentV3Separator = '';
                if (exceptionData.containsKey('step')){
                    paymentV3Separator = String.format('\n ******* STN V3 Payment Nimda Step - {0} ******* \n', new List<String>{(String)exceptionData.get('step')});
                }                
                if (exceptionData.containsKey('calloutRequest')){
                    oppToUpdate.Nimda_Sync_Callout_Request__c = opportunity.Nimda_Sync_Callout_Request__c 
                                                                + paymentV3Separator
                                                                + (String)exceptionData.get('calloutRequest');
                }
                if (exceptionData.containsKey('calloutResponse')){
                    oppToUpdate.Nimda_Sync_Callout_Response__c = opportunity.Nimda_Sync_Callout_Request__c 
                                                                + paymentV3Separator
                                                                + (String)exceptionData.get('calloutResponse');
                }
                updateOpp = true;                                                     
            }
            if (updateOpp){
                update oppToUpdate;
            }
            return true;    
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to apply updates: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{'Opportunity Id : ' + opportunity.Id + ' - ' + ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'applyUpdates', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }    
    /**
    * @description Apply updates to Account and Opportunity record
    * @param Account input account record   
    * @param Opportunity input opportunity record
    * @param Contact decision maker
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean updateAccountAndOpportunity(Account account, Opportunity opportunity, Contact decisionMaker) {
        try {
            // Update Account
            if (account!=null){
                update account;
            }
            // Update Opportunity
            if (opportunity!=null){
                update opportunity;
            }
            // Update Decision Maker
            if (decisionMaker!=null){
                update decisionMaker;
            }            
            // Return true for success
            return true;    
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to update Account and Opportunity: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'updateAccountAndOpportunity', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Insert the Nimda History records
    * @param nimdaHistoryRecordsJsonStr - Serialized Collection of Nimda History records
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean insertNimdaHistoryRecords(String nimdaHistoryRecordsJsonStr) {
        try {
            // parse the json string for a Collection of Nimda History records
            List<Nimda_History__c> nimdaHistoryRecords = (List<Nimda_History__c>)JSON.deserialize(nimdaHistoryRecordsJsonStr, List<Nimda_History__c>.class);
            // Insert the Nimda history records
            if (nimdaHistoryRecords!=null && !nimdaHistoryRecords.isEmpty()){
                insert nimdaHistoryRecords;
            }
            // Return true for success
            return true;    
        } catch (Exception ex){
            System.debug(LoggingLevel.ERROR, 'Failed to insert Nimda History records: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'insertNimdaHistoryRecords', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /**
    * @description Check if the user has permission for the input custom permission api name
    * @param customPermission - Custom permission api name 
    * @return <Boolean> true or false
    **/
    @AuraEnabled
    public static Boolean hasPermission(String customPermission) {
        return FeatureManagement.checkPermission(customPermission);
    }    
    /**
    * @description A custom exception is thrown in the event something goes wrong during the processing in the above operations
    **/   
    public class CDdLtngNimdaSyncCtrlException extends Exception { }
    /**
    * @description: Save the Business Configuration on the Opportunity
    * @@param String opportunityId   
    * @param String input businessOption     
    * @param String input businessId  
    * @return <Boolean> true or false
    **/    
    @AuraEnabled
    public static Boolean saveBusinessConfigurationOnOpportunity(String opportunityId, String businessOption,String businessId) {
        Savepoint sp = Database.setSavepoint();
        try {         
            Opportunity opportunityToUpdate = [Select id,accountId from Opportunity where Id =: Id.valueOf(opportunityId) ];//new Opportunity ( Id = Id.valueOf(opportunityId) );
        if(!String.isBlank(businessOption)){
            opportunityToUpdate.Change_of_Ownership_Business_Option__c = businessOption;      
        }
        if(!String.isBlank(businessId)){
            opportunityToUpdate.Change_of_Ownership_Business_Id__c = integer.valueof(businessId);
        }else{
            opportunityToUpdate.Change_of_Ownership_Business_Id__c = null;
        }
        update opportunityToUpdate;
        return true;          
        } catch (Exception ex){
            Database.rollback(sp);
            System.debug(LoggingLevel.ERROR, 'Failed to update the Business configuration on Opportunity: '+ ex.getMessage());
            CDdErrorUtilities.createApexLogs(new List<String>{ex.getMessage()}, 'CDdLtngNimdaSyncCtrl', 'saveBusinessConfigurationOnOpportunity', LoggingLevel.ERROR);
            throw new AuraHandledException(ex.getMessage());
        }
    }   
}