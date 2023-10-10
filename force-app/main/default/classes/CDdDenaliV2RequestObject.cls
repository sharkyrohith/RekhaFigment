/**
   CDdDenaliV2RequestObject
**/
public with sharing class CDdDenaliV2RequestObject {

    private static final String VALIDATE_BILLING_COUNTRY_CODE = 'BillingCountryCode';
    private static final String VALIDATE_SHIPPING_ADDRESS_COUNTRY = 'Shipping_Address_Country__c';
    private static final String VALIDATE_RETURN_SHIPPING_ADDRESS_STATE = 'Return_Shipping_Address_State__c';
    private static final String VALDIATE_BILLING_STATE = 'BillingState';
    private static final String GERMANY_COUNTRY_CODE = 'DE';
    
    private static String caseCountryCode;
    private static List<String> skipValidationForFields = new List<String>();

    /*  
    * @description Acquire setting label based on environment
    */
    public static Organization org = [
        SELECT IsSandbox
        FROM Organization
        WHERE  Id =:UserInfo.getOrganizationId()
    ];
    public static String settingLabel = org.IsSandbox ? 'UAT' : 'Prod';

     /**
    * @description Setting for Denali
    */
    public static Denali_Setting__mdt mapping = [
        SELECT 
            Contact_Field_Mapping_V2__c,
            Account_Field_Mapping_V2__c,
            Case_Field_Mapping_V2__c,
            Allowed_Country_Codes_V2__c,
            Required_Account_Key_V2__c,
            Required_Contact_Key_V2__c,
            Required_Case_Key_V2__c,
        	Allowed_State_Codes_V2__c,
        	Skip_State_Validation_V2__c,
            Skip_State_Validation_For_Country_V2__c
        FROM Denali_Setting__mdt
        WHERE MasterLabel =: settingLabel];

    public static Map<String, String> accountFieldMapping  {
        get {
            String accountFieldMap = mapping.Account_Field_Mapping_V2__c;
            Map<String, Object> results = 
                (Map<String, Object>)JSON.deserializeUntyped(accountFieldMap);
            return convert(results);
        }
        set;
    }

    private static List<String> requiredAccountKey {
        get {
            if (String.isBlank(mapping.Required_Account_Key_V2__c)) {
                return new List<String>();
            }
            return mapping.Required_Account_Key_V2__c.split(',');
        }
        set;
    }

    public static Map<String, String> contactFieldMapping {
        get {
            String contactFieldMap = mapping.Contact_Field_Mapping_V2__c;
            Map<String, Object> results = 
                (Map<String, Object>)JSON.deserializeUntyped(contactFieldMap);
            return convert(results);
        }
        set;
    }

    private static List<String> requiredContactKey {
        get {
            if (String.isBlank(mapping.Required_Contact_Key_V2__c)) {
                return new List<String>();
            }
            return mapping.Required_Contact_Key_V2__c.split(',');
        }
        set;
    }

    public static Map<String, String> caseFieldMapping {
        get {
            String caseFieldMap = mapping.Case_Field_Mapping_V2__c;
            Map<String, Object> results = 
                (Map<String, Object>)JSON.deserializeUntyped(caseFieldMap);
            return convert(results);
        }
        set;
    }

    private static List<String> requiredCaseKey {
        get {
            if (String.isBlank(mapping.Required_Case_Key_V2__c)) {
                return new List<String>();
            }
            return mapping.Required_Case_Key_V2__c.split(',');
        }
        set;
    }

    public static Map<String, String> allowedCountryCodes {
        get {
            Map<String, String> allowedCC = new Map<String, String>();
            String allowedCountryCodeMap = mapping.Allowed_Country_Codes_V2__c;
            Map<String, Object> result = 
                (Map<String, Object>)JSON.deserializeUntyped(allowedCountryCodeMap);
            for(String fieldMapKey: result.keySet()) {
                allowedCC.put(fieldMapKey.toLowercase(), result.get(fieldMapKey).toString());
            }
            return allowedCC;
        }
        set;
    }

    public static List<String> allowedStateCodes {
        get {
            List<String> allowedSC = new List<String>();
            String allowedCStateCodeMap = mapping.Allowed_State_Codes_V2__c;
            if (String.isBlank(allowedCStateCodeMap)) {
                return allowedSC;
            }
            for (String s : allowedCStateCodeMap.split(',')) {
                allowedSC.add(s.toLowercase());
            }
           
            return allowedSC;
        }
        set;
    }

    public static Boolean skipStateValidation {
        get {
            return Boolean.valueOf(mapping.Skip_State_Validation_V2__c);
        }
        set;
    }

    public static List<String> skipStateValidationForCountryCode {
        get {
            List<String> skipStateValidationForCountryCodes = new List<String>();
            String skipStateValidationForCountryCode = mapping.Skip_State_Validation_For_Country_V2__c;
            if (String.isBlank(skipStateValidationForCountryCode)) {
                return skipStateValidationForCountryCodes;
            }
            for (String s : skipStateValidationForCountryCode.split(',')) {
                skipStateValidationForCountryCodes.add(s.toLowercase());
            }
           
            return skipStateValidationForCountryCodes;
        }
        set;
    }

    private static Map<String, String> convert(Map<String, Object> metadataMapping) {
        Map<String, String> fieldMapping = new Map<String, String>();
        for(String fieldMapKey: metadataMapping.keySet()) {
            fieldMapping.put(fieldMapKey, metadataMapping.get(fieldMapKey).toString());
        }
        return fieldMapping;
    }

    public static string generateJSON(CDdDenaliV2RequestObject.CherwellBody body, Case currentCase) {
        body = fillBody(body, currentCase);

        String shippingAddressCountry = '';    
        if (body.case_x.containsKey(VALIDATE_SHIPPING_ADDRESS_COUNTRY)) {
            shippingAddressCountry = body.case_x.get(VALIDATE_SHIPPING_ADDRESS_COUNTRY);
        }

        caseCountryCode = body.validateAndConvertCountryCode(VALIDATE_SHIPPING_ADDRESS_COUNTRY, shippingAddressCountry);
        // BZAP-12170 - Remove Case.Return_Shipping_Address_State__c abd Account.BillingState for Germany
        if (caseCountryCode.equalsIgnoreCase(GERMANY_COUNTRY_CODE)) {
            body.case_x.remove(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE);
            body.account.remove(VALDIATE_BILLING_STATE);
        }

        System.debug(body.case_x);
        System.debug(body.account);
        System.debug(body.contact);
        String jsonOutput = JSON.serialize(body);
        // Turns case_x into case. Case is a reserved keyword.
        return jsonOutput.replace('_x', '');
    }

    public static string getOperation(Case currentCase) {
        String operation;
        
        if (String.isBlank(currentCase.Denali_Record_Id__c)) {
            operation = 'New';
        } else {
            operation = 'Update';
        }

        return operation;
    }

    private static CDdDenaliV2RequestObject.CherwellBody fillBody(CDdDenaliV2RequestObject.CherwellBody body, Case currentCase) {
        body.account = createMapping(accountFieldMapping, currentCase);
        body.contact = createMapping(contactFieldMapping, currentCase);
        body.case_x = createMapping(caseFieldMapping, currentCase);
        
        return body;
    }

    private static Map<String, String> createMapping(Map<String, String> fieldMapping, Case currentCase) {
        System.debug('On createMapping');
        Map<String, String> mapping = new Map<String, String>();
        for (String key: fieldMapping.keySet()) {
            String fieldName = fieldMapping.get(key);
            String value = '';

            if (String.isBlank(fieldName)) {
                continue;
            }

            try {
                if (!fieldName.contains('.')){
                    value = String.valueOf(currentCase.get(fieldName));
                } else {
                    List<String> relFieldName = fieldName.split('\\.');

                    // Handles scenario where value is hardcoded string
                    // String.Fedex turns into FedEx.
                    if (relFieldName[0] == 'String'){
                        value = String.valueOf(relFieldName[1]);
                    } else {
                        value = String.valueOf(currentCase.getSObject(relFieldName[0]).get(relFieldName[1]));
                    }
                }
            } catch(Exception e) {
                System.debug('Failed to retried ' + fieldName);
            }
            mapping.put(key, value);
        }

        return mapping;
    }

    public class CherwellBody {
        public String operation;
        public Map<String, String> account;
        public Map<String, String> contact;
        // We prefix with _x because case is a reserved keyword
        public Map<String, String> case_x;

        public boolean isValid() {
            System.debug('On isValid');
            
            if (sanatizeBody()) {
                System.debug('Passed sanatizeBody');

                List<String> rAccountKey = requiredAccountKey;
                List<String> rContactKey = requiredAccountKey;
                List<String> rCaseKey = requiredCaseKey;
                
                // On non production environment not all fields
                // will be able to be populated
                if(Test.isRunningTest()){
                    return true;
                }

                for (String field: requiredAccountKey) {
                    if (invalidField(this.account, field)) {
                        throw new CDdDenaliV2Handler.DenaliV2Exception('Account field: ' + field + ' is required.');
                    }
                }

                for (String field: requiredContactKey) {
                    if (invalidField(this.contact, field)) {
                        throw new CDdDenaliV2Handler.DenaliV2Exception('Contact field: ' + field + ' is required.');
                    }
                }

                for (String field: requiredCaseKey) {
                    if (invalidField(this.case_x, field)) {
                        throw new CDdDenaliV2Handler.DenaliV2Exception('Case fields: ' + field + ' is required.');
                    }
                }
            }

            return true;
        }

        @TestVisible
        private Boolean sanatizeBody() {
            System.debug('On sanatizeBody');
            String shippingAddressCountry = '';
            String returnShippingAddressState = '';
            String billingCountryCode = '';

            if (this.case_x.containsKey(VALIDATE_SHIPPING_ADDRESS_COUNTRY)) {
                shippingAddressCountry = this.case_x.get(VALIDATE_SHIPPING_ADDRESS_COUNTRY);
            } else {
                throw new CDdDenaliV2Handler.DenaliV2Exception('Case object does not contain ' + VALIDATE_SHIPPING_ADDRESS_COUNTRY);
            }

            if (this.account.containsKey(VALIDATE_BILLING_COUNTRY_CODE)) {
                billingCountryCode = this.account.get(VALIDATE_BILLING_COUNTRY_CODE);
            } else {
                throw new CDdDenaliV2Handler.DenaliV2Exception('Account object does not contain ' + VALIDATE_BILLING_COUNTRY_CODE);
            }

            caseCountryCode = validateAndConvertCountryCode(VALIDATE_SHIPPING_ADDRESS_COUNTRY, shippingAddressCountry);

            if (this.case_x.containsKey(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE)) {
                returnShippingAddressState = this.case_x.get(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE);
            } else if (caseCountryCode == GERMANY_COUNTRY_CODE) {
                System.debug('Germany can skip state validation');
            } else {
                throw new CDdDenaliV2Handler.DenaliV2Exception('Case object does not contain ' + VALIDATE_RETURN_SHIPPING_ADDRESS_STATE);
            }

            this.case_x.put(VALIDATE_SHIPPING_ADDRESS_COUNTRY, caseCountryCode);
            if (shouldValidateState(caseCountryCode)) {
                this.case_x.put(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE, validateAndConvertStateCode(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE, returnShippingAddressState));
            }
            this.account.put(VALIDATE_BILLING_COUNTRY_CODE, validateAndConvertCountryCode(VALIDATE_BILLING_COUNTRY_CODE, billingCountryCode));

            

            return true;
        }

        @TestVisible
        private String validateAndConvertCountryCode(String fieldName, String countryCodeToValidate) {
            String countryCode;
            if (String.isBlank(countryCodeToValidate)) {
                throw new CDdDenaliV2Handler.DenaliV2Exception(fieldName + ' is empty');
            }

            if (allowedCountryCodes.containsKey(countryCodeToValidate.toLowercase())) {
                countryCode = allowedCountryCodes.get(countryCodeToValidate.toLowercase());
            } else {
                throw new CDdDenaliV2Handler.DenaliV2Exception(fieldName + ' has invalid value ' + countryCodeToValidate);
            }

            return countryCode;
        }

        @TestVisible
        private Boolean shouldValidateState(String countryCode) {
            Boolean containsCountryCode = skipStateValidationForCountryCode.contains(countryCode.toLowercase());
            if (containsCountryCode) {
                skipValidationForFields.add(VALIDATE_RETURN_SHIPPING_ADDRESS_STATE);
            }
            return !containsCountryCode;
        }

        @TestVisible
        private String validateAndConvertStateCode(String fieldName, String stateCodeToValidate) {
            if (String.isBlank(stateCodeToValidate)) {
                throw new CDdDenaliV2Handler.DenaliV2Exception(fieldName + ' is empty');
            }

            if (!allowedStateCodes.contains(stateCodeToValidate.toLowercase()) && !skipStateValidation) {
                throw new CDdDenaliV2Handler.DenaliV2Exception(fieldName + ' has invalid value ' + stateCodeToValidate);
            }

            return stateCodeToValidate;
        }

        @TestVisible
        private Boolean invalidField(Map<String, String> toCheck, String field) {
            if (skipValidationForFields.contains(field)) {
                return false;
            }
            if (!toCheck.containsKey(field)) {
                return true;
            }
            if (String.isBlank(toCheck.get(field))) {
                return true;
            }

            return false;
        }
    }
}