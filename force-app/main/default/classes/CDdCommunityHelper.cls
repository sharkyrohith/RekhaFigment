/**
 *
 * @author: Tia Xuan
 * @date: 2020-06
 * @description Helper class for common community functions
 *
 */
public class CDdCommunityHelper {
    private static final String base64Chars = '' +
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
    'abcdefghijklmnopqrstuvwxyz' +
    '0123456789+/';

    public static final Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    @AuraEnabled
    public static Map<String,List<PicklistEntryWrapper>> getDependentPicklist(String objName, String parentField, String childField){
        Map<String,List<PicklistEntryWrapper>> pickListMap = new Map<String,List<PicklistEntryWrapper>>();

        Schema.sObjectType objType = SOBJECT_TYPES.get(objName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        List<PicklistEntryWrapper> depEntries = (List<PicklistEntryWrapper>)JSON.deserialize(
                            JSON.serialize(objFieldMap.get(childField).getDescribe().getPicklistValues()),
                            List<PicklistEntryWrapper>.class);
        List<String> controllingValues = new List<String>();

        for (Schema.PicklistEntry ple : objFieldMap.get(parentField).getDescribe().getPicklistValues()) {
            PicklistEntryWrapper pew = new PicklistEntryWrapper(ple);
            pickListMap.put(pew.value, new List<PicklistEntryWrapper>());
            controllingValues.add(pew.value);
        }

        for (PicklistEntryWrapper plew : depEntries) {
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    pickListMap.get(controllingValues.get(i)).add(plew);
                }
            }
        }

        return pickListMap;
    }

    public static List<PicklistEntryWrapper> getPicklistValues(String objName, String plField){
        Schema.sObjectType objType = SOBJECT_TYPES.get(objName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> vals = objFieldMap.get(plField).getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> retVals = new List<PicklistEntryWrapper>();
        for (Schema.PicklistEntry pe : vals){
            PicklistEntryWrapper pew = new PicklistEntryWrapper(pe);
            retVals.add(pew);
        }
        return retVals;
    }

    public static List<PicklistEntryWrapper> getCommunityPicklistValues(String objName, String plField){
        Schema.sObjectType objType = SOBJECT_TYPES.get(objName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        List<Schema.PicklistEntry> vals = objFieldMap.get(plField).getDescribe().getPicklistValues();
        List<PicklistEntryWrapper> retVals = initPicklist();
        for (Schema.PicklistEntry pe : vals){
            PicklistEntryWrapper pew = new PicklistEntryWrapper(pe);
            retVals.add(pew);
        }
        return retVals;
    }

    public static List<PicklistEntryWrapper> initPicklist(){
        List<PicklistEntryWrapper> retVals = new List<PicklistEntryWrapper>();
        retVals.add(new PicklistEntryWrapper(Label.DdCommunity_None, ''));
        return retVals;
    }

    // New for Dasher Project W
    public static List<PicklistEntryWrapper> initPicklistYesNo(){
        List<PicklistEntryWrapper> retVals = new List<PicklistEntryWrapper>();
        retVals.add(new PicklistEntryWrapper(Label.DdCommunity_None, ''));
        retVals.add(new PicklistEntryWrapper(Label.DdCommunity_Yes, Label.DdCommunity_Yes));
        retVals.add(new PicklistEntryWrapper(Label.DdCommunity_No, Label.DdCommunity_No));
        return retVals;
    }
    // End for Dasher Project W

    //Refer from here https://salesforce.stackexchange.com/questions/4462/get-lists-of-dependent-picklist-options-in-apex
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }

    public class PicklistEntryWrapper{
        @AuraEnabled
        public String active;
        @AuraEnabled
        public String defaultValue;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public String validFor;

        public PicklistEntryWrapper(Schema.PicklistEntry pe){
            this.label = pe.label;
            this.value = pe.value;
        }

        public PicklistEntryWrapper(String label, String value){
            this.label = label;
            this.value = value;
        }
    }

    public class DependentPicklistEntryWrapper{
        @AuraEnabled
        public String picklistVal;
        @AuraEnabled
        public List<PicklistEntryWrapper> dependentPicklists;

        public DependentPicklistEntryWrapper(String plVal, List<PicklistEntryWrapper> dList){
            picklistVal = plVal;
            dependentPicklists = dList;
        }
    }
}