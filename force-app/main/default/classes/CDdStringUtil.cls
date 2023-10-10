public class CDdStringUtil {
    public static String formatPhoneNum(String phone) {
        return formatPhoneNum(phone, 'US');
    }
    
    public static String formatPhoneNum(String phone, String countryCode) {
        String result = phone;
        if ((countryCode.equals('US') || countryCode.equals('CA')) && phone.length() == 10 && phone.isNumeric()) {
            //should be in the proper format...
            return phone;
        } else {
            // for now we will not handle international numbers nor will we normalize them
            // we will just remove all symbols and non-numeric characters
        }
        
        result = result.replaceAll('[^0-9]', '');
        
        if (countryCode.equals('US') || countryCode.equals('CA')) {
            if (result.indexOf('1') == 0) {
                result = result.substring(1);
            } else if (result.indexOf('01') == 0) {
                result = result.substring(2);
            }
        }

        if (countryCode.equals('AU')){
            if (result.indexOf('61') == 0) {
                result = result.substring(2);
            }            
        }
        
        return result;
    }
    
    public static String stripDecimal(Decimal num) {
        // needed to add null case for when running unit test
        String curr = num.toPlainString();
        try {
            return (num == null) ? '' : (curr.indexOf('.') != -1 ? curr.substringBefore('.') : curr);
        } catch (Exception e) {
            //you can throw an error here if you want, but I'm going to just return an empty string if any exception occurs
            return '';            
        }
    }
    
    /* Takes an input string that includes a single decimal value and extracts the decimal value. 
     * This is accomplished by removing all non-decimal or period characters. 
     * If there are multiple decimal values, this will only return the first one.
     * If there is a combination of decimals and digits without a break (12.34.56), this method will return all of them.
     * Examples:
     *   '$12.34' ==> 12.39
     *   '$12.34 $56.78' ==> 12.34
     *   '$12.34.56.78 test' ==> '12.34.56.78'
	*/
    public static String extractFirstDecimal(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        Pattern nonAlphanumeric = Pattern.compile('[0-9\\.]+');
		Matcher matcher = nonAlphanumeric.matcher(input);
		if (matcher.find()) { 
            return matcher.group(0);
        } else {
            return '';
        }
    }
    
    /* Takes an input string that consists entirely of a single decimal value (representative of a dollar value).
     * Converts that dollar value into cents.
     * Examples:
     *   '2.5' ==> '250'
     *   '7.45' ==> '745'
     *   '3' ==> '300'
    */
    public static String dollarsToCents(String input) {
        if (String.isBlank(input)) {
            return null;
        }
        Integer cents = (double.valueOf(input) * 100).intValue();
		return String.valueOf(cents);
    }
    
    public static List<String> getListOfPotentialPhoneNums (String phoneNum) {
        if (String.isBlank(phoneNum)) {
            return null;
        }
        // generate permutations of phone numbers to match on
        List<String> potentialPhoneNums = new List<String>();
        potentialPhoneNums.add(phoneNum);
        potentialPhoneNums.add('(' + phoneNum.substring(0, 3) + ') ' + phoneNum.substring(3, 6) + '-' + phoneNum.substring(6));
        potentialPhoneNums.add('+1' + phoneNum);
        potentialPhoneNums.add('+1 (' + phoneNum.substring(0, 3) + ') ' + phoneNum.substring(3, 6) + '-' + phoneNum.substring(6));
        return potentialPhoneNums;
    }

    /* 
    * @description: This function accepts two addresses, replaces street name abbreviations like Rd, St to their 
    *               long form and compares the two addresses. Returns true if they are a match.
    * @parmas:  Address address1 
    *           Address address2
    */

    public static boolean compareAddress(Address address1, Address address2) {
        
        String street1; 
        String street2; 
        List<Address_Mapping__mdt> addressMappings = [SELECT DeveloperName, Id, Label, Language, Long_Name__c, 
                                                        MasterLabel, NamespacePrefix, QualifiedApiName 
                                                        FROM Address_Mapping__mdt];

        
        if((address1 == null && address2 != null) || (address1 != null && address2 == null)) {
            return false;
        } else if (address1 == null && address2 == null){
            return true; 
        }
        if (!String.isEmpty(address1.Street) && !String.isEmpty(address2.Street)) {
            street1 = address1.Street.toLowerCase(); 
            street2 = address2.Street.toLowerCase(); 
            for(Address_Mapping__mdt addressMapping : addressMappings) {
                // replace " Road" to " Rd"
                // Have to do this manipulation in code since custom metadata truncates leading and trailing spaces.
                street1 = street1.replaceAll(' ' + addressMapping.Long_Name__c.toLowerCase(), ' ' + addressMapping.Label.toLowerCase()); 
                street2 = street2.replaceAll(' ' + addressMapping.Long_Name__c.toLowerCase(), ' ' + addressMapping.Label.toLowerCase()); 
            }
        } 
        if(!caseInsensitveStringCompare(street1, street2)) {
            return false; 
        } else if(!caseInsensitveStringCompare(address1.City, address2.City)) {
            return false; 
        } else if(!caseInsensitveStringCompare(address1.State,address2.State)) {
            return false;
        } else if(address1.countryCode != address2.countryCode) {
            return false; 
        }
        return true; 
    }

    /* 
    * @description: This function checks if the strings are null/empty and then compares after converting them to lower case
    */
    public static Boolean caseInsensitveStringCompare(String string1, String string2) {
        
        if(string1 == null && string2 == null) {
            return true; 
        }
        else if(String.isEmpty(string1) && !String.isEmpty(string2) 
                || !String.isEmpty(string1) && String.isEmpty(string2)) {
            return false; 
        } else {
            string1 = string1.toLowerCase();
            string2 = string2.toLowerCase(); 
            if(string1 == string2){
                return true; 
            } else {
                return false; 
            }
        }
    }
}