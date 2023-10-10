/********************************************************************************************************************
* @author Lathika 
* @date 04/15/2022
*
* @group Merchant Services
*
* @description CDdMxOrderBatch to process Open Mx Orders (Where Mx Order records does not have an Order ID populated),BZAP-14359
*
**************************************************************************************************************************************/
global class CDdMxOrderBatch implements Database.Batchable<sObject> {
    /**
     * @description static variables defined here
     */ 
    public static final String CASE_RECORD_TYPE_ID_TABLET_REQUESTS = CDdMxSxConstants.CASE_RECORD_TYPE_ID_TABLET_REQUESTS;
    public static final String VENDOR_SOCIALMOBILE = CDdMxSxConstants.MX_VENDOR_SOCIAL_MOBILE;

    public static final String QUERY_TO_GENERATE_MX_ORDER = ' SELECT Id, RecordTypeId, Status, (SELECT Id, Case__c FROM Mx_Orders__r) '
                                                            + ' FROM Case '
                                                            + ' WHERE RecordTypeId = :CASE_RECORD_TYPE_ID_TABLET_REQUESTS '
                                                            + ' AND LastModifiedDate = LAST_N_DAYS:{0} '
                                                            + ' AND Id NOT IN (SELECT Case__c FROM Mx_Order__c) '
                                                            + ' AND Status IN (\'Open\',\'Opened\') '                                         
                                                            + ' ORDER BY LastModifiedDate DESC ';     
    public static final String QUERY_TO_PROCESS_MX_ORDER = ' SELECT Id '
                                                            + ' FROM Mx_Order__c '
                                                            + ' WHERE Mx_Order__c.Order_Id__c = NULL '
                                                            + ' AND LastModifiedDate = LAST_N_DAYS:{0} '                                      
                                                            + ' ORDER BY LastModifiedDate DESC ';
                                                            
    public static final String MX_ORDER_STATUS_SHIPPED = CDdMxSxConstants.MX_ORDER_STATUS_SHIPPED;
    public static final String QUERY_TO_SEND_MX_ORDER_RETURN_LABEL = 'Select Id, Name,Order_Status_Description__c,Case__r.ContactEmail,Case__r.Case_Owner_Email__c,'
                                                                    +' Account__r.Owner.Email,OwnerId,'
                                                                    +' (select id from Attachments order by Createddate desc limit 1)'
                                                                    +' from Mx_Order__c where Order_Status__c = :MX_ORDER_STATUS_SHIPPED' 
        															+' AND Type_Of_Mx_Order__c = \'Return\''
       																+' AND vendor__c =:VENDOR_SOCIALMOBILE'
        															+' AND LastModifiedDate >= LAST_N_DAYS:{0}'
        															+' ORDER BY LastModifiedDate DESC';                                                        

    public static final Map<CDdMxOrderBatchEnum, String> QUERY_MAP = new Map<CDdMxOrderBatchEnum, String>{
        CDdMxOrderBatchEnum.GENERATE_MX_ORDER => QUERY_TO_GENERATE_MX_ORDER,
        CDdMxOrderBatchEnum.PROCESS_MX_ORDER => QUERY_TO_PROCESS_MX_ORDER,
        CDdMxOrderBatchEnum.SEND_MX_ORDER_RETURN_LABEL => QUERY_TO_SEND_MX_ORDER_RETURN_LABEL
    };                                                          
    /**
     * @description class variables defined here
     */      
    private CDdMxOrderBatchEnum batchEnum;
    private CDdMxOrderBatchConfig config;
    /** 
    * @description A single argument constructor
    * @param lastModifiedDays - How many days do you go in the past, to read the Mx Order records
    */
    public CDdMxOrderBatch(CDdMxOrderBatchEnum batchEnum){
        this.batchEnum = batchEnum;
        this.config = new CDdMxOrderBatchConfig(this.batchEnum);
    }   
    /** 
    * @description Start the batch operation and prepare the Query to get the MxOrder records
    */      
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String soqlQuery = String.format(QUERY_MAP.get(this.batchEnum), new List<String>{String.valueOf(config.getLastNDays())});
        return Database.getQueryLocator(soqlQuery);
    }
    /** 
    * @description Execute the batch operation for the scoped sObject records
    */  
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        Set<Id> sObjectIds = new Set<Id>();
        for (SObject obj : scope){
            sObjectIds.add((Id)obj.get('Id'));
        }
        switch on this.batchEnum {
            when GENERATE_MX_ORDER {
                CDdMxOrderEventHelper.publishGenerateMxOrderEvents(scope);
            }
            when PROCESS_MX_ORDER {
                new CDdMxOrderProcessor(config.getSObjectType(), sObjectIds).execute();
            }
            when SEND_MX_ORDER_RETURN_LABEL {
                new CDdMxOrderBatchSendemailHelper().sendingEmail(scope);
            }
        } 
    }
    /** 
    * @description Finish the batch operation
    */  
    global void finish(Database.BatchableContext BC) {     
    }
}