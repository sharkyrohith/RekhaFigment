/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 12/15/2020
*
* @group Nimda ByPass Tool
*
* @description This is the config helper class relevant to STN (Bulk) ByPass Tool functionality 
* - Determines what ByPass Groups the User is configured for 
* - Determines what fields the ByPass Tool User is eligible to work with  
* - ByPass Tool fields may be
*   a) Store Fields
*   b) Store Partnership Fields
* - Following custom metadata tables/definitions are used to house the configuration
*   1) Nimda Bypass Group (Nimda_Bypass_Group__mdt)
*   2) Nimda Bypass Group Permission (Nimda_Bypass_Group_Permission__mdt)
*   3) Nimda Store Field Definition (Nimda_Store_Field_Definition__mdt)
*   4) Nimda Store Partnership Field Definition (Nimda_Store_Partnership_Field_Definition__mdt)            
* 
**************************************************************************************************************************************/
public class CDdNimdaByPassGroupHelper {
    public static final String BYPASS_GROUP_PERMISSIONS_SQL_QUERY_FIELDS = 
                                                    'SELECT Id, Label, DeveloperName '
                                                    + ', Permission_Type__c, Permission_Id__c, Permission_Name__c ';
    public static final String BYPASS_GROUP_PERMISSIONS_SQL_FROM =  ' FROM Nimda_Bypass_Group_Permission__mdt ';
    public static final String BYPASS_GROUP_PERMISSIONS_SQL_WHERE =  ' WHERE Active__c = true ';
    public static String BYPASS_GROUP_PERMISSIONS_SQL_PARAMETERIZED = BYPASS_GROUP_PERMISSIONS_SQL_QUERY_FIELDS
                                                                    + '{0}'     
                                                                    + BYPASS_GROUP_PERMISSIONS_SQL_FROM
                                                                    + BYPASS_GROUP_PERMISSIONS_SQL_WHERE;
    public static final String NIMDA_STORE_FIELDS_SQL_QUERY_FIELDS = 
                                                    'SELECT Id, Label, DeveloperName '
                                                    + ', Display_Type__c, API_Type__c ';
    public static final String NIMDA_STORE_FIELDS_SQL_FROM =  ' FROM Nimda_Store_Field_Definition__mdt ';                                                    
    public static String NIMDA_STORE_FIELDS_SQL_PARAMETERIZED = NIMDA_STORE_FIELDS_SQL_QUERY_FIELDS
                    + '{0}'     
                    + NIMDA_STORE_FIELDS_SQL_FROM;
    public static final String NIMDA_STORE_PARTNERSHIP_FIELDS_SQL_QUERY_FIELDS = 
                                                    'SELECT Id, Label, DeveloperName '
                                                    + ', Display_Type__c, API_Type__c ';                    
    public static final String NIMDA_STORE_PARTNERSHIP_FIELDS_SQL_FROM =  ' FROM Nimda_Store_Partnership_Field_Definition__mdt ';
    public static String NIMDA_STORE_PARTNERSHIP_SQL_PARAMETERIZED = NIMDA_STORE_PARTNERSHIP_FIELDS_SQL_QUERY_FIELDS
                    + '{0}'     
                    + NIMDA_STORE_PARTNERSHIP_FIELDS_SQL_FROM;
    public static final Set<String> NIMDA_TABLE_SQL_PARAMETERIZED 
                    = new Set<String>{NIMDA_STORE_FIELDS_SQL_PARAMETERIZED, NIMDA_STORE_PARTNERSHIP_SQL_PARAMETERIZED};                                                                                                               
    public static final String CURRENT_USER_ID = UserInfo.getUserId();
    public static final String CURRENT_PROFILE_ID = UserInfo.getProfileId();
    /**
    * @description Return a Collection of Nimda Store and Store Partnership fields 
    * - Evaluates what ByPass Groups the User is configured for 
    * - Evaluates what fields the ByPass Tool User is eligible to work with 
    * Example of Collection structure returned is as follows
        [   {
                "apiType" : "Boolean",
                "displayType" : "Boolean",
                "displayName" : "Offers Delivery",
                "property" : "offers_delivery"
            }, {
                "apiType" : "String",
                "displayType" : "Percent",
                "displayName" : "Commission Rate",
                "property" : "commission_rate"
        }   ]
    * @param 
    * @return List<Map<String, String>> A collection of Nimda Store and Store Partnership fields
    **/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getNimdaFields(){
        return getNimdaFields(getPermittedByPassGroups());
    }    
    /**
    * @description Retrieve the eligible ByPass Groups 
    *   It is based on the logged in user, the associated profile and the additional permission sets and/or Groups
    *   configured in the permission custom metadata for a ByPass Group (Nimda_Bypass_Group_Permission__mdt)
    * @param  
    * @return Set<String> Return a collection of eligible ByPass Groups
    **/ 
    public static Set<String> getPermittedByPassGroups(){
        Set<String> permittedByPassGroups = new Set<String>();
        // Define a master collection that maintains if permission is allowed (true or false), based on key permission id
        Map<String, Boolean> masterCollectionOfPermittedByPermissionId = new Map<String, Boolean>();
        // Define a master Collection of all permission ids (across bypass groups), grouped by Permission Type 
        Map<String, Set<String>> masterCollectionOfPermissionIdsByType = new Map<String, Set<String>>();
        Map<String, Map<String, Set<String>>> byPassGroupPermissionsByGroup = getNimdaByPassGroupPermissionsByGroup();
        // a. Collect all the Permission Ids for various permission types across all groups
        //    Reason - SOQL query for objects PermissionSetAssignment, GroupMember is minimized to a single invocation
        for (String byPassGroupDeveloperName : byPassGroupPermissionsByGroup.keySet()){
            for (String permissionType : byPassGroupPermissionsByGroup.get(byPassGroupDeveloperName).keySet()){
                Set<String> permissionIds = byPassGroupPermissionsByGroup.get(byPassGroupDeveloperName).get(permissionType);
                for (String permissionId : permissionIds){
                    if (masterCollectionOfPermissionIdsByType.containsKey(permissionType)){
                        masterCollectionOfPermissionIdsByType.get(permissionType).add(permissionId);
                    } else {
                        masterCollectionOfPermissionIdsByType.put(permissionType, new Set<String>{permissionId});
                    }
                }
            }
        }
        // b. Update the master collection - masterCollectionOfPermittedByPermissionId
        for (String permissionType : masterCollectionOfPermissionIdsByType.keySet()){
            Set<String> permissionIds = masterCollectionOfPermissionIdsByType.get(permissionType);
            Map<String, Boolean> permissions = getPermissions(permissionType, permissionIds);
            for (String permissionId : permissions.keySet()){
                masterCollectionOfPermittedByPermissionId.put(permissionId, permissions.get(permissionId));
            }
        }
        // c. Walk through the Collection of Permission Ids by Permission Type for each ByPass Group,
        //    to determine if the ByPass group is a permitted group for the Current User
        for (String byPassGroupDeveloperName : byPassGroupPermissionsByGroup.keySet()){
            Map<String, Set<String>> permissionIdsByType = byPassGroupPermissionsByGroup.get(byPassGroupDeveloperName);
            for (String permissionType : permissionIdsByType.keySet()){
                Set<String> permissionIds = permissionIdsByType.get(permissionType);
                for (String permissionId : permissionIds){
                    if (masterCollectionOfPermittedByPermissionId.get(permissionId)){
                        permittedByPassGroups.add(byPassGroupDeveloperName);
                    }
                }
            }
        }
        return permittedByPassGroups;
    }
    /**
    * @description Query/Evaluate the appropriate permission type to determine 
    *   if the permission ids are eligible for a ByPass group
    * @param <String> permissionType
    * @param Set<String> permissionIds   
    * @return Map<String, Boolean> A collection of Nimda ByPass Group PermissionIds with permission as false
    **/ 
    public static Map<String, Boolean> getPermissions(String permissionType, Set<String> permissionIds){
        Map<String, Boolean> permMap = getDefaultPermissionMap(permissionIds);
        switch on permissionType {
            when 'User' {
                if (permMap.containsKey(CURRENT_USER_ID)){
                    permMap.put(CURRENT_USER_ID, true);
                }
            }
            when 'Profile' {
                if (permMap.containsKey(CURRENT_PROFILE_ID)){
                    permMap.put(CURRENT_PROFILE_ID, true);
                }
            }
            when 'PermissionSet' {
                for (PermissionSetAssignment psa : [SELECT Id, PermissionSetId, AssigneeId 
                                                    FROM PermissionSetAssignment
                                                    WHERE PermissionSetId IN :permissionIds
                                                    AND AssigneeId = :CURRENT_USER_ID]){
                    if (permMap.containsKey(psa.PermissionSetId)){
                        permMap.put(psa.PermissionSetId, true);
                    }                                        
                }
            }
            when 'Group' {
                for (GroupMember gMem : [SELECT Id, GroupId, UserOrGroupId
                                                    FROM GroupMember
                                                    WHERE GroupId IN :permissionIds
                                                    AND UserOrGroupId = :CURRENT_USER_ID]){
                    if (permMap.containsKey(gMem.GroupId)){
                        permMap.put(gMem.GroupId, true);
                    }                                        
                }
            }                                    
        }
        return permMap;
    }
    /**
    * @description Default the permissions to false
    * @param 
    * @return Map<String, Boolean> A collection of Nimda ByPass Group PermissionIds with permission as false
    **/    
    public static Map<String, Boolean> getDefaultPermissionMap(Set<String> permissionIds){
        Map<String, Boolean> permMap = new Map<String, Boolean>();
        for (String permissionId : permissionIds){
            permMap.put(permissionId, false);
        }
        return permMap;        
    }
    /**
    * @description Return a Collection of ByPass Group Permissions using the following structure
    * For Outer Collection,
    *   Key is the ByPass Group DeveloperName
    *   Value is the Collection of Permission Ids grouped by Permission Type
    * For Inner Collection
    *   Key is the ByPass Group Permission Type
    *   Value is the Collection of Permission Identifiers belonging to a specific Permission Type
    * @param 
    * @return Map<String, Map<String, Set<String>>> A collection of Nimda ByPass Group Permissions
    **/
    public static Map<String, Map<String, Set<String>>> getNimdaByPassGroupPermissionsByGroup(){
        Map<String, String> groupFieldAPINames = getNimdaByPassGroupFieldAPINames();
        Map<String, Map<String, Set<String>>> byPassGroupPermissionsByGroup = new Map<String, Map<String, Set<String>>>();
        String additionalQueryParams = ',' + String.join(groupFieldAPINames.values(), ',');
        for (Nimda_Bypass_Group_Permission__mdt byPassGroupPermission : Database.query(String.format(BYPASS_GROUP_PERMISSIONS_SQL_PARAMETERIZED, new List<String>{additionalQueryParams}))){
            for (String byPassGroupDeveloperName : groupFieldAPINames.keySet()){
                // 1. If exists, extract the Permission Ids by Type Collection for a ByPass group
                Map<String, Set<String>> permissionIdsByType = 
                    byPassGroupPermissionsByGroup.containsKey(byPassGroupDeveloperName)
                        ? byPassGroupPermissionsByGroup.get(byPassGroupDeveloperName)
                        : new  Map<String, Set<String>>();
                // 2. Update the Permission Ids by Type Collection (for a ByPass group)
                //    Duplicate permission Ids will be replaced using the <Set> Collection 
                if ((Boolean)byPassGroupPermission.get(groupFieldAPINames.get(byPassGroupDeveloperName)) == true){
                    if (permissionIdsByType.containsKey(byPassGroupPermission.Permission_Type__c)){
                        permissionIdsByType.get(byPassGroupPermission.Permission_Type__c).add(byPassGroupPermission.Permission_Id__c);
                    } else {
                        permissionIdsByType.put(byPassGroupPermission.Permission_Type__c, new Set<String>{byPassGroupPermission.Permission_Id__c});
                    }
                }
                // 3. If the Permission Ids by Type Collection is not empty, associate this with the ByPass group
                if (!permissionIdsByType.isEmpty()){
                    byPassGroupPermissionsByGroup.put(byPassGroupDeveloperName, permissionIdsByType);
                }
            }                          
        }
        return byPassGroupPermissionsByGroup; 
    }
    /**
    * @description Return a Collection of Map object with 
    * key as Nimda Group Developer Name
    * Value as Nimda Group Field API Name
    * Note : Nimda Group Field API Name is a reference field of type 'Checkbox' found on the following custom metadata
    * a) Nimda_Bypass_Group_Permission__mdt
    * b) Nimda_Store_Field_Definition__mdt
    * c) Nimda_Store_Partnership_Field_Definition__mdt 
    * @param 
    * @return Map<String, String> A collection of Nimda ByPass Group Field API Name
    **/    
    public static Map<String, String> getNimdaByPassGroupFieldAPINames() {
        Map<String, String> fieldAPINames = new Map<String, String>();
        for (String groupDeveloperName : getNimdaByPassGroups().keySet()){
            fieldAPINames.put(groupDeveloperName, groupDeveloperName + '__c');
        }
        return fieldAPINames;
    }
    /**
    * @description Return a Collection of Map object with 
    * key as Nimda Group Developer Name
    * Value as Nimda Group Label
    * @param 
    * @return Map<String, String> A collection of Nimda ByPass Groups
    **/
    public static Map<String, String> getNimdaByPassGroups(){
        Map<String, String> byPassGroups = new Map<String, String>();
        for (Nimda_Bypass_Group__mdt byPassGroup : [SELECT Id, Label, DeveloperName
                                                   FROM Nimda_Bypass_Group__mdt]){
            byPassGroups.put(byPassGroup.DeveloperName, byPassGroup.Label);                                        
        }
        return byPassGroups; 
    }
    /**
    * @description Return a Collection of Nimda Store and Store Partnership fields
    * @param Set<String> byPassGroupDeveloperNames
    * @return List<Map<String, String>> A collection of Nimda Store and Store Partnership fields
    **/
    public static List<Map<String, String>> getNimdaFields(Set<String> byPassGroupDeveloperNames){
        List<Map<String, String>> nimdaFields = new List<Map<String, String>>();
        Set<String> nimdaProperty = new Set<String>();
        for (String parameterizedSql : NIMDA_TABLE_SQL_PARAMETERIZED){
            for (Map<String, String> nimdaField : getNimdaFields(parameterizedSql, byPassGroupDeveloperNames)){
                if (!nimdaProperty.contains(nimdaField.get('property'))){
                    nimdaFields.add(nimdaField);       
                    nimdaProperty.add(nimdaField.get('property'));
                }
            }
        }
        return nimdaFields; 
    }
    /**
    * @description Return a Collection of Nimda fields from the object found within the parameterized sql
    * @param String parameterizedSql    
    * @param Set<String> byPassGroupDeveloperNames
    * @return List<Map<String, String>> A collection of Nimda fields
    **/    
    public static List<Map<String, String>> getNimdaFields(String parameterizedSql, Set<String> byPassGroupDeveloperNames){
        List<Map<String, String>> nimdaFields = new List<Map<String, String>>();
        Map<String, String> groupFieldAPINames = new Map<String, String>();
        for (String groupDeveloperName : byPassGroupDeveloperNames){
            groupFieldAPINames.put(groupDeveloperName, groupDeveloperName + '__c');
        }
        String additionalQueryParams = ',' + String.join(groupFieldAPINames.values(), ',');
        for (SObject nimdaField : Database.query(String.format(parameterizedSql, new List<String>{additionalQueryParams}))){
            for (String byPassGroupDeveloperName : groupFieldAPINames.keySet()){
                if ((Boolean)nimdaField.get(groupFieldAPINames.get(byPassGroupDeveloperName)) == true){
                    nimdaFields.add(new Map<String, String>{
                        'property' => (String)nimdaField.get('DeveloperName')
                        , 'displayName' => (String)nimdaField.get('Label')                                
                        , 'displayType' => (String)nimdaField.get('Display_Type__c')
                        , 'apiType' => (String)nimdaField.get('API_Type__c')
                    });
                }
            }
        }
        return nimdaFields;         
    }
}