/**
* @author Veera
* @date 2021-11
* @description Utility class for international code changes
*/
public with sharing class CDdI18nUtility {
   
    public static final String COUNTRY_CODE_AUSTRALIA = 'AU';
    public static final String COUNTRY_NAME_AUSTRALIA = 'Australia';
    public static final String COUNTRY_CODE_GERMANY = 'DE';
    public static final String COUNTRY_NAME_GERMANY = 'Germany';
    public static final String COUNTRY_CODE_NEWZEALAND = 'NZ';
    public static final String COUNTRY_NAME_NEWZEALAND = 'New Zealand';
    public static final String COUNTRY_CODE_JAPAN = 'JP';
    public static final String COUNTRY_NAME_JAPAN = 'Japan';
    public static final String COUNTRY_CODE_CANADA = 'CA';
    public static final String COUNTRY_NAME_CANADA = 'Canada';
    public static final String COUNTRY_CODE_US = 'US';
    public static final String COUNTRY_NAME_UNITED_STATES = 'United States';
    public static final String STATE_CODE_PUERTO_RICO = 'PR';
    public static final String STATE_NAME_PUERTO_RICO = 'Puerto Rico';

    private static Set<String> eligibleCountryCodesforCaseOwnerChange = new Set<String> {'CA','US','AU'};
    private static Set<String> eligibleCountryNamesforCaseOwnerChange = new Set<String> {'Canada', 'United States','Australia'};
    private static Set<String> excludeCountryCodePhoneFormatting = new Set<String> {'CA', 'US', 'JP'};
    private static Map<String, List<String>> phoneFieldsByObject = new Map<String, List<String>> {
        'Lead' => new List<String>{'Phone', 'Mobile_Phone__c'},
        'Account' => new List<String>{'Phone'},
        'Contact' => new List<String>{'Phone', 'Mobile_Phone__c'}
    };
    private static Map<String, String> sObjectNameToCountryFieldNameMap = CDdI18nDefaultValueMappingUtil.sObjectNameToCountryFieldNameMap;

    /**
     * @author Veera
     * @date 2021-11
     * @description BZAP-12548
     * To keep special characters on the street address when smarty streets to update
     * TODO[Veera] : Re-visit or deprecate this method in future after smarty street allows special characters
     */
    public static Boolean handleSpecialCharsOnLeadChange(String countryCode, String oldStreet, String newStreet){
        Boolean keepOldAddress = false;
        if(isCountryGermany(countryCode) && String.isNotBlank(newStreet) && String.isNotBlank(oldStreet) && 
            !newStreet.equalsIgnoreCase(oldStreet) && 
            !oldStreet.equalsIgnoreCase(oldStreet.escapeUnicode()) && 
            newStreet.equalsIgnoreCase(newStreet.escapeUnicode())){
                newStreet = newStreet.toLowerCase();
                if(newStreet.contains('str.')){
                    newStreet = newStreet.replace('str.', 'straße');
                }
                if(newStreet.getLevenshteinDistance(oldStreet.toLowerCase()) < 5){
                    keepOldAddress = true;
                }
        } 
        return keepOldAddress;
    }
   
    public static Boolean isCountryGermany(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
            (COUNTRY_CODE_GERMANY.equalsIgnoreCase(countryCodeOrName) || 
            COUNTRY_NAME_GERMANY.equalsIgnoreCase(countryCodeOrName));
    }

    public static Boolean isCountryNewZealand(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
            (COUNTRY_CODE_NEWZEALAND.equalsIgnoreCase(countryCodeOrName) || 
            COUNTRY_NAME_NEWZEALAND.equalsIgnoreCase(countryCodeOrName));
    }

    public static Boolean isCountryAustralia(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
            (COUNTRY_CODE_AUSTRALIA.equalsIgnoreCase(countryCodeOrName) || 
            COUNTRY_NAME_AUSTRALIA.equalsIgnoreCase(countryCodeOrName));
    }

    public static Boolean isCountryJAPAN(String countryCodeOrName) { 
        return String.isNotBlank(countryCodeOrName) &&
            (COUNTRY_CODE_JAPAN.equalsIgnoreCase(countryCodeOrName) || 
            COUNTRY_NAME_JAPAN.equalsIgnoreCase(countryCodeOrName));
    }
      
    public static Boolean isCountryCANADA(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
             (COUNTRY_CODE_CANADA.equalsIgnoreCase(countryCodeOrName) || 
             COUNTRY_NAME_CANADA.equalsIgnoreCase(countryCodeOrName));
    }

    public static Boolean isCountryUSA(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
             (COUNTRY_CODE_US.equalsIgnoreCase(countryCodeOrName) || 
             COUNTRY_NAME_UNITED_STATES.equalsIgnoreCase(countryCodeOrName));
    }

    public static Boolean isStatePR(String stateCodeOrName) {
        return String.isNotBlank(stateCodeOrName) &&
             (STATE_CODE_PUERTO_RICO.equalsIgnoreCase(stateCodeOrName) || 
             STATE_NAME_PUERTO_RICO.equalsIgnoreCase(stateCodeOrName));
    }

    /**
    * @author Ila Maheshwari
    * @date 2022-08
    * @description BASD-31125
    * This utility method checks if account's billing country is US/CAN/AUS
    */
    public static Boolean isCountryEligibleForCaseOwnerChange(String countryCodeOrName) {
        return String.isNotBlank(countryCodeOrName) &&
             (eligibleCountryCodesforCaseOwnerChange.contains(countryCodeOrName) || 
             eligibleCountryNamesforCaseOwnerChange.contains(countryCodeOrName));
    }
    
    /**
    * @author Nathalie Mendezona
    * @date 2021-12
    * @description BZAP-12745
    * This utility method formats phone numbers to remove empty spaces (allowed by validation rules)
    */
    public static List<SObject> updateInternationalPhoneNumbers(List<SObject> newList, Map<Id, SObject> oldMap, String sObjectType, Boolean isInsert) {
        List<String> phoneFieldNames = phoneFieldsByObject.get(sObjectType);
        String countryCodeField = sObjectNameToCountryFieldNameMap.get(sObjectType);
        for (SObject record : newList) {
            String countryCode = (String) record.get(countryCodeField);
            if (String.isBlank(countryCode)) {
                continue;
            }
            for (String phoneFieldName: phoneFieldNames) {
                String phoneValue = (String) record.get(phoneFieldName);
                if (!excludeCountryCodePhoneFormatting.contains(countryCode)) {
                    if ((isInsert || phoneValue != oldMap.get((String) record.get('Id')).get(phoneFieldName)) && !String.isEmpty(phoneValue)) {
                        phoneValue = phoneValue.replace(' ', '');
                        record.put(phoneFieldName, phoneValue);
                    }
                }
            }
        }
        return newList;
    }

    /**
     * @author : Abhijeet K
     * @description BZAP-14111 : OCUS: Prefix +1 to all canada phone numbers 
    */
    public static String formatPhoneNumberCanadaForOCUS(Case caseRec) {
        String contactPhone = caseRec.ContactPhone;
        if(String.isNotBlank(contactPhone) && !contactPhone.startsWith('+1')) {
            contactPhone = '+1' + contactPhone;
        }
        return contactPhone;
    }

    /**
     * @author : Abhijeet K
     * @description BZAP-13592 : SSMO: Phone number format update 
     */
    public static string formatJPPhoneNumber(String phoneNumber) {
        String jpFormat = ''; //+81 XX-XXXX-XXXX OR +81 XXX-XXX-XXX
        phoneNumber = phoneNumber.deleteWhitespace();
        if(phoneNumber.startsWith('+81')) {
            phoneNumber = phoneNumber.removeStart('+81');
        }
        if(phoneNumber.length() == 9) {
            jpFormat = '+81 ' + (phoneNumber.substring(0,3)) + '-' + (phoneNumber.substring(3,6)) + '-' +(phoneNumber.substring(6,9));
        } else if(phoneNumber.length() == 10) {
            jpFormat = '+81 ' + (phoneNumber.substring(0,2)) + '-' + (phoneNumber.substring(2,6)) + '-' +(phoneNumber.substring(6,10));
        }
        return jpFormat;
    }
      /**
       * @author Abhijeet K
       * @date 2022-02
       * @description BZAP-13591: SSMO : Address updates on Japan Account
       * To keep special characters on the street address when smarty streets to update
       * Additional details : Not used custom settings/Custom metadata bcz of governer limits 
       */
    public static Map<String, String> getLatinToKanjiStateMap() {
        return new Map<String, String> {
            'Aichi' => '愛知県',
            'Akita' => '秋田県',
            'Aomori' => '青森県',
            'Chiba' => '千葉県',
            'Ehime' => '愛媛県',
            'Fukui' => '福井県',
            'Fukuoka' => '福岡県',
            'Fukushima' => '福島県',
            'Gifu' => '岐阜県',
            'Gunma' => '群馬県',
            'Hiroshima' => '広島県',
            'Hokkaidō' => '北海道',
            'Hyōgo' => '兵庫県',
            'Ibaraki' => '茨城県',
            'Ishikawa' => '石川県',
            'Iwate' => '岩手県',
            'Kagawa' => '香川県',
            'Kagoshima' => '鹿児島県',
            'Kanagawa' => '神奈川県',
            'Kōchi' => '高知県',
            'Kumamoto' => '熊本県',
            'Kyoto' => '京都府',
            'Mie' => '三重県',
            'Miyagi' => '宮城県',
            'Miyazaki' => '宮崎県',
            'Nagano' => '長野県',
            'Nagasaki' => '長崎県',
            'Nara' => '奈良県',
            'Niigata' => '新潟県',
            'Ōita' => '大分県',
            'Okayama' => '岡山県',
            'Okinawa' => '沖縄県',
            'Osaka' => '大阪府',
            'Saga' => '佐賀県',
            'Saitama' => '埼玉県',
            'Shiga' => '滋賀県',
            'Shimane' => '島根県',
            'Shizuoka' => '静岡県',
            'Tochigi' => '栃木県',
            'Tokushima' => '徳島県',
            'Tokyo' => '東京都',
            'Tottori' => '鳥取県',
            'Toyama' => '富山県',
            'Wakayama' => '和歌山県',
            'Yamagata' => '山形県',
            'Yamaguchi' => '山口県',
            'Yamanashi' => '山梨県'	 
        };
    }
}