public class CDdCustomMetadata {

    public class CDdCustomMetadataException extends Exception {}
    private static Map<String, Business_Vertical_Mapping__mdt> businessVerticalMap = null;

    // Custom Metadata methods for Batch and Trigger Settings -- Batch_and_Trigger_Setting__mdt

    public static Map<String, Batch_and_Trigger_Setting__mdt> settingsMap {
        get {
            if (settingsMap == null) {
                settingsMap = new Map<String, Batch_and_Trigger_Setting__mdt>();
                try {
                    List<Batch_and_Trigger_Setting__mdt> settings = [
                        SELECT Id, Label, DeveloperName, Batch_Size__c, Custom_Number__c, Disabled__c, Recursion__c
                        FROM Batch_and_Trigger_Setting__mdt
                    ];
                    for (Batch_and_Trigger_Setting__mdt setting : settings) settingsMap.put(setting.DeveloperName, setting);
                }
                catch (Exception eX) {
                    String customMessage = 'Unable to initialize Batch and Trigger Settings Map.';
                    List<String> messages = new List<String> {eX.getMessage(), customMessage};
                    CDdErrorUtilities.createApexLogs(messages, 'CDdCustomMetadata', 'settingsMap.get', System.LoggingLevel.Error);
                    throw new CDdCustomMetadataException(customMessage);
                }
            }
            return settingsMap;
        }
        private set;
    }

    public static final Integer defaultBatchSize = 200;         // Default Batch Size is 200
    public static final Boolean defaultDisabled = false;        // Default (wherever used by name) is Enabled
    public static final Integer defaultRecursion = 2;           // Default Recursion Depth for a Trigger is 2x

    public static Batch_and_Trigger_Setting__mdt getBatchAndTriggerMetadata(String Name) {
        Batch_and_Trigger_Setting__mdt setting = settingsMap.get(Name);
        return setting;
    }

    public static Integer getBatchSize(Batch_and_Trigger_Setting__mdt Setting) {
        if (Setting == null) return defaultBatchSize;
        if (Setting.Batch_Size__c == null) return defaultBatchSize;
        return (Integer)Setting.Batch_Size__c;
    }

    public static Integer getBatchSize(String Name) {
        return getBatchSize(getBatchAndTriggerMetadata(Name));
    }

    public static Boolean isDisabled(Batch_and_Trigger_Setting__mdt Setting) {
        if (Setting == null) return defaultDisabled;
        if (Setting.Disabled__c == null) return defaultDisabled;
        if (test.isRunningTest()) return defaultDisabled;   // required to successfuly execute unit tests and deploy
        return Setting.Disabled__c;
    }

    public static Boolean isDisabled(String Name) {
        return isDisabled(getBatchAndTriggerMetadata(Name));
    }

    public static Integer getRecursion(Batch_and_Trigger_Setting__mdt Setting) {
        if (Setting == null) return defaultRecursion;
        if (Setting.Recursion__c == null) return defaultRecursion;
        return (Integer)Setting.Recursion__c;
    }

    public static Integer getRecursion(String Name) {
        return getRecursion(getBatchAndTriggerMetadata(Name));
    }

    public static Integer getCustomNumber(Batch_and_Trigger_Setting__mdt Setting) {
        if (Setting == null) return null;   // no defaults for this
        if (Setting.Custom_Number__c == null) return null;
        return (Integer)Setting.Custom_Number__c;
    }

    public static Integer getCustomNumber(String Name) {
        return getCustomNumber(getBatchAndTriggerMetadata(Name));
    }

    // Custom Metadata methods for CDdBatchCaseToClose -- Batch_Case_To_Close__mdt

    public static List<Batch_Case_To_Close__mdt> getBatchCaseCloseList() {
        return [
            SELECT Id, Label, DeveloperName, Active__c, Order__c, Record_Type__c, Logic__c,
                Status_Criteria__c, Hours__c, Criteria__c, OmitProfileCheck__c, SkipOnWrap__c, Where_Clause__c
            FROM Batch_Case_To_Close__mdt
            ORDER BY Order__c ASC
        ];
    }

    // Custom Metadata methods for Id Metadata -- Id_Metadata__mdt

  @testVisible  private static Map<String, String> IdMetadata {
        get {
            if (IdMetadata == null) {
                IdMetadata = new Map<String, String>();
                try {
                    system.debug('Id metadata property');
                    List<Id_Metadata__mdt> values = [
                        SELECT Id, Label, DeveloperName, Category__c, Id__c
                        FROM Id_Metadata__mdt
                    ];
                    for (Id_Metadata__mdt value : values) IdMetadata.put(value.DeveloperName, value.Id__c);
                }
                catch (Exception eX) {
                    String customMessage = 'Unable to initialize Id Metadata Map.';
                    List<String> messages = new List<String> {eX.getMessage(), customMessage};
                    CDdErrorUtilities.createApexLogs(messages, 'CDdCustomMetadata', 'IdMetadata.get', System.LoggingLevel.Error);
                    throw new CDdCustomMetadataException(customMessage);
                }
            }
            return IdMetadata;
        }
      //  private set;
        set;
    }

    public static String getIdValueFor(String key) {
        return IdMetadata.get(key);
    }

    // Custom Metadata methods for Profile Values -- Profile_Values__mdt

    public static Map<String, String> ProfileValues {
        get {
            if (ProfileValues == null) {
                ProfileValues = new Map<String, String>();
                try {
                    List<Profile_Values__mdt> values = [
                        SELECT Id, Label, DeveloperName, Profile_Id__c
                        FROM Profile_Values__mdt
                    ];
                    for (Profile_Values__mdt value : values) ProfileValues.put(value.DeveloperName, value.Profile_Id__c);
                }
                catch (Exception eX) {
                    String customMessage = 'Unable to initialize Profile Values Map.';
                    List<String> messages = new List<String> {eX.getMessage(), customMessage};
                    CDdErrorUtilities.createApexLogs(messages, 'CDdCustomMetadata', 'ProfileValues.get', System.LoggingLevel.Error);
                    throw new CDdCustomMetadataException(customMessage);
                }
            }
            return ProfileValues;
        }
        private set;
    }

    public static String getProfileValueFor(String key) {
        return ProfileValues.get(key);
    }

    // Custom Metadata methods for User License -- User_License__mdt

    public static List<User_License__mdt> getUserLicenseList() {
        String query = 'SELECT Id, Label, DeveloperName, ';
        query += 'Profiles__c, Permission_Set_Licenses__c, Package_Licenses__c, Roles__c ';
        query += 'FROM User_License__mdt ';
        if (test.isRunningTest())
            query += 'WHERE DeveloperName = \'REQUIRED_FOR_UNIT_TESTS\'';
        else
            query += 'WHERE DeveloperName != \'REQUIRED_FOR_UNIT_TESTS\'';
        return database.query(query);
    }

    // Converts a delimited list of Profiles found in Profile_Values__mdt to a Set containing the IDs
    public static Set<Id> profileIDs(String DelimitedNames, String Delimiter) {
        Set<Id> profiles = new Set<Id>();
        if (!String.isBlank(DelimitedNames)) {
            List<String> profileNames = DelimitedNames.split(Delimiter);
            for (String profile : profileNames)
                profiles.add(getProfileValueFor(profile.trim()));
        }
        return profiles;
    }

    // Converts a delimited list of names into a set of strings
    public static Set<String> names(String DelimitedNames, String Delimiter) {
        Set<String> strings = new Set<String>();
        if (!String.isBlank(DelimitedNames)) {
            for (String name : DelimitedNames.split(Delimiter))
                strings.add(name.trim());
        }
        return strings;
    }

    public static Map<Id, Set<Id>> getProfileLicenseMap() {
        Map<Id, Set<Id>> ProfileLicenses = new Map<Id, Set<Id>>();
        List<User_License__mdt> userLicenses = getUserLicenseList();
        Set<String> pslNames = new Set<String>();
        Set<String> pkgNames = new Set<String>();
        for (User_License__mdt userLicense : userLicenses) {
            pslNames.addAll(names(userLicense.Permission_Set_Licenses__c, ','));
            pkgNames.addAll(names(userLicense.Package_Licenses__c, ','));
        }
        Map<String, Id> pslIDs = new Map<String, Id>();
        Map<String, Id> pkgIDs = new Map<String, Id>();
        if (pslNames.size() > 0)
            for (PermissionSetLicense psl : [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel IN :pslNames])
                pslIDs.put(psl.MasterLabel, psl.Id);
        if (pkgNames.size() > 0)
            for (PackageLicense pkg : [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix IN :pkgNames])
                pkgIDs.put(pkg.NamespacePrefix, pkg.Id);
        for (User_License__mdt userLicense : userLicenses) {
            Set<Id> profiles = profileIDs(userLicense.Profiles__c, ',');
            for (Id pid : profiles) {
                Set<Id> permissions = ProfileLicenses.get(pid);
                if (permissions == null) permissions = new Set<Id>();
                for (String perm : names(userLicense.Permission_Set_Licenses__c, ',')) {
                    Id permission = pslIDs.get(perm);
                    if (permission != null) permissions.add(permission);
                }
                for (String perm : names(userLicense.Package_Licenses__c, ',')) {
                    Id permission = pkgIDs.get(perm);
                    if (permission != null) permissions.add(permission);
                }
                ProfileLicenses.put(pid, permissions);
            }
        }
        return ProfileLicenses;
    }

    // provides a map of Role Name to a Set of desired license IDs for the role
    public static Map<String, Set<Id>> getRoleLicenseMap(){
        Map<String, Set<Id>> RoleLicenses = new Map<String, Set<Id>>();
        List<User_License__mdt> userLicenses = getUserLicenseList();
        Set<String> pslNames = new Set<String>();
        Set<String> pkgNames = new Set<String>();

        for (User_License__mdt userLicense : userLicenses) {
            pslNames.addAll(names(userLicense.Permission_Set_Licenses__c, ','));
            pkgNames.addAll(names(userLicense.Package_Licenses__c, ','));
        }
        Map<String, Id> pslIDs = new Map<String, Id>();
        Map<String, Id> pkgIDs = new Map<String, Id>();
        if (pslNames.size() > 0)
            for (PermissionSetLicense psl : [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel IN :pslNames])
                pslIDs.put(psl.MasterLabel, psl.Id);
        if (pkgNames.size() > 0)
            for (PackageLicense pkg : [SELECT Id, NamespacePrefix FROM PackageLicense WHERE NamespacePrefix IN :pkgNames])
                pkgIDs.put(pkg.NamespacePrefix, pkg.Id);
        for (User_License__mdt userLicense : userLicenses) {
            for(String role: names(userLicense.Roles__c, ',')){

                Set<Id> permissions = RoleLicenses.containsKey(role) ? RoleLicenses.get(role) : null ;
                //Set<Id> permissions = RoleLicenses.get(role);
                if (permissions == null) permissions = new Set<Id>();

                for (String perm : names(userLicense.Permission_Set_Licenses__c, ',')) {
                    if(pslIDs.containsKey(perm)){
                        permissions.add(pslIDs.get(perm));
                    }
                }
                for (String perm : names(userLicense.Package_Licenses__c, ',')) {
                    if(pkgIDs.containsKey(perm)){
                        permissions.add(pkgIDs.get(perm));
                    }
                }
                RoleLicenses.put(role, permissions);
            }
        }
        return RoleLicenses;
    }

    /**
     * @author      Nayana
     * @date        August 2021
     * @jira        https://doordash.atlassian.net/browse/BIZS-348
     * @description Pull the Id_Metadata__mdt by Category
     */
    public static Map<String, Id_Metadata__mdt> idMetadataByCategory(String category) {
        Map<String,Id_Metadata__mdt> mapIdMetadata = new Map<String,Id_Metadata__mdt>();
        for(Id_Metadata__mdt idMdt : Id_Metadata__mdt.getall().values()){
            if(String.isNotBlank(idMdt.Category__c) && idMdt.Category__c == category){
                mapIdMetadata.put(idMdt.DeveloperName, idMdt);
            }
        }
        return mapIdMetadata;
    }

    /**
     * @author      Mahesh Chouhan
     * @date        March 2022
     * @jira        https://doordash.atlassian.net/browse/BIZS-961
     * @description Get all Business_Vertical_Mapping__mdt records
     */
    public static Map<String, Business_Vertical_Mapping__mdt> getBusinessVerticalMappings() {
        if (businessVerticalMap != null) {
            return businessVerticalMap;
        }
        businessVerticalMap = new Map<String, Business_Vertical_Mapping__mdt>();
        for(Business_Vertical_Mapping__mdt verticalMapping : Business_Vertical_Mapping__mdt.getall().values()){
            businessVerticalMap.put(verticalMapping.Business_Vertical_ID__c, verticalMapping);
        }
        return businessVerticalMap;
    }
    // End of Custom Metadata methods ...

}