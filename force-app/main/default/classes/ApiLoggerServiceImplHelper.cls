public without sharing class ApiLoggerServiceImplHelper {
    public class ApiLoggerGateFieldsWrapper {
        public String gateField;
        public String relatedToIdFilterField;
        public String relatedToOwnerIdFilterField;
        public ApiLoggerGateFieldsWrapper(String gateField,String relatedToIdFilterField,String relatedToOwnerIdFilterField) {
            this.gateField = gateField;
            this.relatedToIdFilterField = relatedToIdFilterField;
            this.relatedToOwnerIdFilterField = relatedToOwnerIdFilterField;
        }
    }

    public static ApiLoggerGateFieldsWrapper getApiLoggerGateInfo(String productOrToolName) {
        switch on productOrToolName {
            when 'Sendbird' {
                return new ApiLoggerGateFieldsWrapper(
                    'Enable_Sendbird_Logging__c',
                    'Sendbird_Record_Id__c',
                    'Sendbird_Record_Owner_Id__c'
                );
            }
        }
        return null;
    }

    public static Boolean shouldLog(String productOrToolName) {
        ApiLoggerGateFieldsWrapper gateFields = ApiLoggerServiceImplHelper.getApiLoggerGateInfo(productOrToolName);
        if (gateFields == null) {
            return false;
        }

        Api_Logger_Gate__c gate = ApiLoggerGateSelector.newInstance().getOrgDefaults();
        if (gate == null || gate.Id == null) {
            return false;
        }

        Boolean gateField = (Boolean)gate.get(gateFields.gateField);
        if (gateField == null || gateField == false) {
            return false;
        }
        return true;
    }

    public static Boolean shouldLog(String productOrToolName,String relatedToId, String relatedToOwnerId) {
        ApiLoggerGateFieldsWrapper gateFields = ApiLoggerServiceImplHelper.getApiLoggerGateInfo(productOrToolName);
        if (gateFields == null) {
            return false;
        }

        Api_Logger_Gate__c gate = ApiLoggerGateSelector.newInstance().getOrgDefaults();
        if (gate == null || gate.Id == null) {
            return false;
        }

        Boolean gateField = (Boolean)gate.get(gateFields.gateField);
        if (gateField == null || gateField == false) {
            return false;
        }

        String relatedToIdToCompare = (String)gate.get(gateFields.relatedToIdFilterField);
        if (String.isNotBlank(relatedToIdToCompare) && (String.isBlank(relatedToId) || (String.isNotBlank(relatedToId) && !relatedToIdToCompare.containsIgnoreCase(relatedToId)))) {
            return false;
        }

        String relatedToOwnerIdToCompare = (String)gate.get(gateFields.relatedToOwnerIdFilterField);
        if (String.isNotBlank(relatedToOwnerIdToCompare) && (String.isBlank(relatedToOwnerId) || (String.isNotBlank(relatedToOwnerId) && !relatedToOwnerIdToCompare.containsIgnoreCase(relatedToOwnerId)))) {
            return false;
        }

        return true;
    }
}