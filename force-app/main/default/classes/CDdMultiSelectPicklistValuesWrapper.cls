/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Wrapper used by lwcDdMultiSelectPicklist lwc/CDdMutliSelectPicklist code -- it contains keyword and result
 *             When user is typing at any speed, its important to tie the keyword against the result so that
 *             race conditions in server calls dont end up messing up the dropdown results with inaccurate values not corresponding
 *             to the current keyword in the UI.
 */
 public class CDdMultiSelectPicklistValuesWrapper {
    @AuraEnabled public String keyWord {get;set;}
    @AuraEnabled public List<CDdMultiSelectPicklistWrapper> values {get;set;}

    public CDdMultiSelectPicklistValuesWrapper(){
        this.keyWord = CDdCoreConstants.BLANK_STRING;
        this.values = new List<CDdMultiSelectPicklistWrapper>();
    }

    public CDdMultiSelectPicklistValuesWrapper(String keyWord,
        List<CDdMultiSelectPicklistWrapper> values) {
        this.keyWord = keyWord;
        this.values = values;
    }
}