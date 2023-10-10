/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 09/12/2019
*
* @group Apex Batch
*
* @description A batch job that retrieves Leads that are not associated to a Parent Account but possesses a valid Business Id
*   For such Leads, a Parent Account is created using existing values from the corresponding Lead (such as Business Id, Owner Id etc.)
*   Once the Parent Account is created, it is associated with the corresponding Lead based on foreign key 'Business Id'
*   Note: If a Parent Account already exists for the Business Id, then that Parent Account will be associated with the Lead record
*
**************************************************************************************************************************************/
global class CDdLeadUpdateParentAccountBatch implements Database.Batchable<sObject> {
    public static final String DEVELOPER_NAME_ACCOUNT_PARENT_ACCOUNT = 'Account_Parent_Account'; 
    public static final String DEVELOPER_NAME_LEAD_MASTER_LEAD = 'Lead_Master_Lead';
    public static final Set<String> DEVELOPER_NAME_RECORD_TYPE_SET = new Set<String>{DEVELOPER_NAME_ACCOUNT_PARENT_ACCOUNT, DEVELOPER_NAME_LEAD_MASTER_LEAD};    
    public static final String RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT;
    public static final String RECORD_TYPE_ID_LEAD_MASTER_LEAD;                       
    public static final Set<String> BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS_STRINGS;
    public static final String OWNER_TYPE_USER = 'User';
    public static final String DEVELOPER_NAME_HOLDING_USER = 'Holding_User';
    public static final String USER_ID_HOLDING_USER;
    static {
        for (Record_Type_Values__mdt recordTypeValue : [SELECT DeveloperName, Record_Type_Id_18__c 
                                                        FROM Record_Type_Values__mdt 
                                                        WHERE DeveloperName IN :DEVELOPER_NAME_RECORD_TYPE_SET]){
            if (DEVELOPER_NAME_ACCOUNT_PARENT_ACCOUNT.equals(recordTypeValue.DeveloperName)){
                RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT = recordTypeValue.Record_Type_Id_18__c;
            }
            if (DEVELOPER_NAME_LEAD_MASTER_LEAD.equals(recordTypeValue.DeveloperName)){
                RECORD_TYPE_ID_LEAD_MASTER_LEAD = recordTypeValue.Record_Type_Id_18__c;
            }            
        }
        for (User_Value__mdt userValue : [SELECT DeveloperName, User_Id__c 
                                        FROM User_Value__mdt 
                                        WHERE DeveloperName = :DEVELOPER_NAME_HOLDING_USER]){
            USER_ID_HOLDING_USER = userValue.User_Id__c;
        }
        BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS_STRINGS = new Set<String>();
        for (Business_Id_With_No_Parent_Account__mdt value : [SELECT DeveloperName, Business_ID__c
                                                            FROM Business_Id_With_No_Parent_Account__mdt]){
            BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS_STRINGS.add(value.Business_ID__c.stripTrailingZeros().toPlainString());
        }
    }      
    private static final String QUERY = 'SELECT Id, Name, Company, Owner.Type, OwnerId, Business_ID__c, Parent_Account__c '
                + ' FROM Lead '
                + ' WHERE RecordTypeId IN :leadRecordTypeIds '
                + ' AND IsConverted = false '
                + ' AND Parent_Account__c = NULL '
                + ' AND Business_ID__c != NULL ';
    /** 
    * @description Start the batch operation and prepare the Query to locate the Account records for field copy
    */      
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Set<Id> leadRecordTypeIds = new Set<Id>{RECORD_TYPE_ID_LEAD_MASTER_LEAD};
        return Database.getQueryLocator(QUERY);
    }
    /** 
    * @description Execute the batch operation for field copy on the scoped Lead records
    */  
    global void execute(Database.BatchableContext BC, List<Lead> leads) {
        Map<Id, Lead> leadsMap = new Map<Id, Lead>();
        Map<Id, Account> newParentAccountsByLeadId = new Map<Id, Account>();        
        Map<Decimal, Lead> leadsByBusinessId = new Map<Decimal, Lead>();
        Map<Decimal, Account> parentAccountsByBusinessId = new Map<Decimal, Account>();
        Id parentAccountRecordTypeId = RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT;
        List<String> errorMessages = new List<String>();
        for (Lead l : leads){
            if (!BUSINESS_ID_WITH_NO_PARENT_ACCOUNTS_STRINGS.contains(l.Business_ID__c.stripTrailingZeros().toPlainString())){
                leadsMap.put(l.Id, l);
                leadsByBusinessId.put(l.Business_ID__c.stripTrailingZeros(), l);
            }
        } 
        for (Account a : [  SELECT Id, Business_ID__c, Name, OwnerId, RecordTypeId
                            FROM Account
                            WHERE RecordTypeId = :parentAccountRecordTypeId
                            AND Business_ID__c != null
                            AND Business_ID__c IN :leadsByBusinessId.keySet()
                        ]){
            parentAccountsByBusinessId.put(a.Business_ID__c.stripTrailingZeros(), a);
        }        
        for (Decimal businessId : leadsByBusinessId.keySet()){
            Lead lead = leadsByBusinessId.get(businessId);
            if (parentAccountsByBusinessId.containsKey(businessId)){
                lead.Parent_Account__c = parentAccountsByBusinessId.get(businessId).Id;
            } else {
                String leadCompanyName = String.isNotBlank(lead.Company) ? Lead.Company.trim() : '';
                String leadName = leadCompanyName.contains('(') 
                                        ?   leadCompanyName.substringBefore('(').trim() 
                                        :   (leadCompanyName.contains('[') 
                                                ? leadCompanyName.substringBefore('[').trim() 
                                                : leadCompanyName.trim()
                                            );
                String newParentAccountName = leadName
                                                +  ' '
                                                + '[Parent-' + lead.Business_ID__c.stripTrailingZeros().toPlainString() + ']';
                newParentAccountsByLeadId.put(lead.Id,
                                new Account(
                                Name = newParentAccountName
                                , Business_ID__c = lead.Business_ID__c
                                , OwnerId = (lead.Owner.Type == OWNER_TYPE_USER ? lead.OwnerId : USER_ID_HOLDING_USER)
                                , RecordTypeId = parentAccountRecordTypeId                            
                            )
                        );
            }
        }
        Savepoint savePointBeforeUpdate = Database.setSavepoint();
        try{
            if (!newParentAccountsByLeadId.isEmpty()){
                Database.SaveResult[] insertResults = Database.insert(newParentAccountsByLeadId.values(), false);
                errorMessages.addAll(CDdErrorUtilities.processSaveResults(insertResults, new List<String>()));
                for (Id leadId : newParentAccountsByLeadId.keySet()){
                    Lead lead = leadsMap.get(leadId);
                    lead.Parent_Account__c = newParentAccountsByLeadId.get(leadId).Id;
                }
            }
            if (!leadsMap.isEmpty()){
                Database.SaveResult[] updateResults = Database.update(leadsMap.values(), false);
                errorMessages.addAll(CDdErrorUtilities.processSaveResults(updateResults, new List<String>()));
            }
            if(!errorMessages.isEmpty()){
                CDdErrorUtilities.createApexLogs(errorMessages, 'CDdLeadCreateParentAccountBatch');
            }                
        } catch(Exception ex) {
            Database.rollback(savePointBeforeUpdate);
        }                
    }
    /** 
    * @description Finish the batch operation
    */  
    global void finish(Database.BatchableContext BC) {
    }
}