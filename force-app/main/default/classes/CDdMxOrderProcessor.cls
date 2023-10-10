/********************************************************************************************************************
* @author Sriram
* @date 04/07/2022
*
* @group Merchant Services
*
* @description Mx Order Processor
* 1. Get open Mx Order records (i.e. Order Id is NULL OR lookup reference to Mx Order Queue is NULL)
*      If sObject Type is 'Account', use the field 'Account__c' as filter on the Mx_Order__c record
*      If sObject Type is 'Case', use the field 'Case__c' as filter on the Mx_Order__c record
*      If sObject Type is 'Mx_Order__c', use the field 'Id' as filter on the Mx_Order__c record
* 2. Run the open Mx Orders via the processor
* 3. For invalid Mx Orders, set the error and update the Mx Orders
* 4. For queueable Mx Orders,
*      Publish the Mx Order Event - CDdMxOrderEventEnum.QUEUE_MX_ORDER
* 5. For retryable Mx Orders,
*      Update the existing Mx Order Queue by incrementing the Attempt (Attempt__c)
**************************************************************************************************************************************/
public class CDdMxOrderProcessor {
    /**
     * Define static variables here
     */
    public static Map<String, String> MX_ORDER_FILTER_FIELD_API_BY_SOBJECT_TYPE =
        new Map<String, String>{
            CDdMxSxConstants.SOBJECT_TYPE_ACCOUNT => 'Account__c',
            CDdMxSxConstants.SOBJECT_TYPE_CASE => 'Case__c',
            CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER => 'Id'
        };
    public static String SOQL_QUERY_GET_OPEN_MX_ORDERS =    ' SELECT Id, Order_Id__c, Mx_Order_Queue__c,State__c, Mx_Order_Queue__r.Attempt__c, Mx_Order_Queue__r.LastModifiedDate, '
                                                            + ' Case__c, Case__r.Status, Case__r.Origin, Case__r.Request_Type__c, Account__c, '
                                                            + ' Account__r.RecordTypeId, Account__r.RecordType.Name, '
                                                            + ' Country_Code__c, Case__r.Shipping_Type__c, Case__r.Return_Shipping_Address_State__c, '
                                                            + ' Contact__c, Contact_Email__c, Contact_First_Name__c,Contact_Last_Name__c, Contact_Phone__c, '
                                                            + ' Case__r.Opportunity_Name__c, Case__r.Proposed_Date_of_Tablet__c ,Case__r.Opportunity_Name__r.Proposed_Date_of_Tablet__c,Store_Order_Protocol__c '
                                                            + ' FROM Mx_Order__c '
                                                            + ' WHERE {0} IN :sObjectIds '
                                                            + ' AND Order_Id__c = NULL '
                                                            + ' AND Case__c != NULL ';
    /**
     * Define class variables here
     */
    private String sObjectType;
    private Set<Id> sObjectIds;
    private Map<Id, Mx_Order__c> mxOrders {
        get {
            if (this.mxOrders == null){
                this.setMxOrders();
            }
            return this.mxOrders;
        }
        private set;
    }
    private CDdMxOrderAccountHelper accountHelper {
        get {
            if (this.accountHelper == null){
                this.setAccountHelper();
            }
            return this.accountHelper;
        }
        private set;
    }
    public Map<Id, Mx_Order__c> notReadyToProcessMxOrders {
        get {
            if (this.notReadyToProcessMxOrders == null){
                this.setNotReadyToProcessMxOrders();
            }
            return this.notReadyToProcessMxOrders;
        }
        private set;
    }
    public Map<Id, Mx_Order__c> invalidMxOrders {
        get {
            if (this.invalidMxOrders == null){
                this.setInvalidMxOrders();
            }
            return this.invalidMxOrders;
        }
        private set;
    }
    public Map<Id, Mx_Order__c> queueableMxOrders {
        get {
            if (this.queueableMxOrders == null){
                this.setQueueableMxOrders();
            }
            return this.queueableMxOrders;
        }
        private set;
    }
    public Map<Id, Mx_Order_Queue__c> retryableMxOrders {
        get {
            if (this.retryableMxOrders == null){
                this.setRetryableMxOrders();
            }
            return this.retryableMxOrders;
        }
        private set;
    }
    /**
     * Default Constructor
     * @param sObjectType - valid values are Account, Case, Mx_Order__c
     * @param sObjectIds - sObject record ids belonging to relevant sObjectType
     * @return
     */
    public CDdMxOrderProcessor(String sObjectType, Set<Id> sObjectIds) {
        this.sObjectType = sObjectType;
        this.sObjectIds = sObjectIds;
    }
    /**
     * @description
     * 1. For invalid Mx Orders, set the error and update the Mx Orders
     * 2. For queueable Mx Orders,
     *      Publish the Mx Order Event - CDdMxOrderEventEnum.QUEUE_MX_ORDER
     * 3. For retryable Mx Orders,
     *      Update the existing Mx Order Queue by incrementing the Attempt (Attempt__c)
     * @param
     * @return
     */
    public void execute(){
        List<Mx_Order__c> ordersToUpdate = new List<Mx_Order__c>();
        if (!this.invalidMxOrders.isEmpty()){
            ordersToUpdate.addAll(this.invalidMxOrders.values());
        }
        if (!this.notReadyToProcessMxOrders.isEmpty()){
            ordersToUpdate.addAll(this.notReadyToProcessMxOrders.values());
        }
        if (!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
        }
        if (!this.queueableMxOrders.isEmpty()){
            new CDdMxOrderEventPublisher(CDdMxOrderEventEnum.QUEUE_MX_ORDER, CDdMxSxConstants.SOBJECT_TYPE_MX_ORDER, this.queueableMxOrders.values()).publish();
        }
        if (!this.retryableMxOrders.isEmpty()){
            update this.retryableMxOrders.values();
        }
    }
    /**
     * @description Set the Open Mx Orders (i.e. Orders that can be processed) using filter for input sObjectType
     * @param
     * @return
     */
    private void setMxOrders(){
        String query = String.format(SOQL_QUERY_GET_OPEN_MX_ORDERS, new List<String>{ MX_ORDER_FILTER_FIELD_API_BY_SOBJECT_TYPE.get( this.sObjectType )});
        Set<String> caseStatusToExclude = new Set<String>();
        if (!CDdMxSxConstants.MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE.isEmpty()){
            caseStatusToExclude.addAll(CDdMxSxConstants.MX_ORDER_OPEN_CASE_STATUS_TO_EXCLUDE);
            query = query + ' AND Case__r.Status NOT IN :caseStatusToExclude ';
        }
        this.mxOrders = new Map<Id, Mx_Order__c>((List<Mx_Order__c>)Database.query(query));
    }
    /**
     * @description Set the Account Helper for Mx Order
     * @param
     * @return
     */
    private void setAccountHelper(){
        this.accountHelper = new CDdMxOrderAccountHelper(this.mxOrders);
    }
    /**
     * @description Set the invalid Mx Orders
     * @param
     * @return
     */
    private void setNotReadyToProcessMxOrders(){
        this.notReadyToProcessMxOrders = new Map<Id, Mx_Order__c>();
        for (Id mxOrderId : this.mxOrders.keySet()){
            Mx_Order__c mxOrder = this.mxOrders.get(mxOrderId);
            if (!this.isReadyToProcess(mxOrder)){
                String msg = this.isFuturePDOT(mxOrder) ? CDdMxSxConstants.MX_ORDER_FUTURE_PDOT_DATE_ERROR_MESSAGE : CDdMxSxConstants.MX_ORDER_MILESTONE_COMPLETE_ERROR_MESSAGE;
                this.notReadyToProcessMxOrders.put(
                    mxOrderId,
                    new Mx_Order__c(
                        Id = mxOrderId,
                        Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_OPEN,
                        Order_Status_Last_Modified_Date__c = System.now(),
                        Order_Status_Description__c = msg
                    )
                );
            }
        }
    }
    /**
     * @description Set the invalid Mx Orders
     * @param
     * @return
     */
    private void setInvalidMxOrders(){
        this.invalidMxOrders = new Map<Id, Mx_Order__c>();
        Map<Id, List<String>> validationErrors = new CDdMxOrderValidator(this.accountHelper, this.mxOrders).validate();
        for (Id mxOrderId : validationErrors.keySet()){
            if (isReadyToProcess(this.mxOrders.get(mxOrderId)) && !validationErrors.get(mxOrderId).isEmpty()){
                this.invalidMxOrders.put(
                    mxOrderId,
                    new Mx_Order__c(
                        Id = mxOrderId,
                        Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_INVALID,
                        Order_Status_Last_Modified_Date__c = System.now(),
                        Order_Status_Description__c = String.join(validationErrors.get(mxOrderId), ';')
                    )
                );
            }
        }
    }
    /**
     * @description Set the Queueable Mx Orders
     * @param
     * @return
     */
    private void setQueueableMxOrders(){
        this.queueableMxOrders = new Map<Id, Mx_Order__c>();
        for (Id mxOrderId : this.mxOrders.keySet()){
            Mx_Order__c mxOrder = this.mxOrders.get(mxOrderId);
            if (this.isQueueableMxOrder(mxOrder)){
                this.queueableMxOrders.put(mxOrderId, mxOrder);
            }
        }
    }
    /**
     * @description Set the Retryable Mx Orders
     * @param
     * @return
     */
    private void setRetryableMxOrders(){
        this.retryableMxOrders = new Map<Id, Mx_Order_Queue__c>();
        for (Id mxOrderId : this.mxOrders.keySet()){
            Mx_Order__c mxOrder = this.mxOrders.get(mxOrderId);
            if (this.isRetryableMxOrder(mxOrder)){
                this.retryableMxOrders.put(mxOrderId, new Mx_Order_Queue__c(
                    Id = mxOrder.Mx_Order_Queue__c,
                    Mx_Order__c = mxOrderId,
                    Attempt__c = (mxOrder.Mx_Order_Queue__r.Attempt__c != null ? ++mxOrder.Mx_Order_Queue__r.Attempt__c : 1)
                ));
            }
        }
    }
    /**
     * @description Is the Mx Order valid?
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isValid(Mx_Order__c mxOrder){
        return !this.invalidMxOrders.containsKey(mxOrder.Id);
    }
    /**
     * @description Are Milestones applicable for the Mx Order?
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isMilestonesApplicable(Mx_Order__c mxOrder){
        return CDdMxSxConstants.MILESTONE_APPLICABLE_CASE_REQUEST_TYPES.contains(mxOrder.Case__r.Request_Type__c);
    }
    /**
     * @description Are relevant Milestones available for the associated Account found on the Mx Order?
     * Note: Relevant Milestones are - Review & Triage, Setup Store
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean hasMilestones(Mx_Order__c mxOrder){
        return this.accountHelper.hasMilestones(mxOrder.Account__c);
    }
    /**
     * @description Are relevant Milestones complete for the Mx Order?
     * Note: Relevant Milestones are - Review & Triage, Setup Store
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isMilestonesComplete(Mx_Order__c mxOrder){
        return this.accountHelper.isMilestoneComplete(mxOrder.Account__c, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE)
                &&
                this.accountHelper.isMilestoneComplete(mxOrder.Account__c, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE);
    }
    /**
     * @description Is any of the relevant Milestones blocked for the Mx Order?
     * Note: Relevant Milestones are - Review & Triage, Setup Store
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isMilestoneBlocked(Mx_Order__c mxOrder){
        return this.accountHelper.isMilestoneBlocked(mxOrder.Account__c, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_REVIEW_AND_TRIAGE)
                ||
                this.accountHelper.isMilestoneBlocked(mxOrder.Account__c, CDdMxSxConstants.MILESTONE_RECORD_TYPE_ID_SETUP_STORE);
    }
    /**
     * @description Is the Mx order queueable?
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isQueueableMxOrder(Mx_Order__c mxOrder){
        return isReadyToProcess(mxOrder) && isValid(mxOrder) && String.isBlank(mxOrder.Order_Id__c) && String.isBlank(mxOrder.Mx_Order_Queue__c);
    }
    /**
     * @description Is the Mx order retryable?
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isRetryableMxOrder(Mx_Order__c mxOrder){
        return isReadyToProcess(mxOrder) && isValid(mxOrder) && String.isBlank(mxOrder.Order_Id__c) && String.isNotBlank(mxOrder.Mx_Order_Queue__c) && (System.now() >= mxOrder.Mx_Order_Queue__r.LastModifiedDate.addMinutes(CDdMxSxConstants.MX_ORDER_SUBMISSION_MIN_ELAPSED_MINUTES));
    }
    /**
     * @description Is the Mx Order ready to be processed?
     * Note : If this method returns false, do not mark the Mx Order as invalid, even if the Mx Order Validator returns error(s) for the Mx Order record
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isReadyToProcess(Mx_Order__c mxOrder){
        return (!isFuturePDOT(mxOrder)) && (isNotAffectedByMilestone(mxOrder));
    }
    /**
     * @description Is the Mx Order not affected by the Milestone?
     * Note : If this method returns false, do not mark the Mx Order as invalid, even if the Mx Order Validator returns error(s) for the Mx Order record
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isNotAffectedByMilestone(Mx_Order__c mxOrder){
        return ( (!isMilestonesApplicable(mxOrder)) || (hasMilestones(mxOrder) && (isMilestonesComplete(mxOrder) || isMilestoneBlocked(mxOrder))) || (!hasMilestones(mxOrder)) );
    }
    /**
     * @description Is the Proposed Date of Tablet in the future?
     * Note : If this method returns false, do not mark the Mx Order as invalid, even if the Mx Order Validator returns error(s) for the Mx Order record
     * @param Mx_Order__c mxOrder
     * @return Boolean
     */
    private Boolean isFuturePDOT(Mx_Order__c mxOrder){
        return (String.isNotBlank(mxOrder.Case__c) && (mxOrder.Case__r.Proposed_Date_of_Tablet__c != null) && (mxOrder.Case__r.Proposed_Date_of_Tablet__c > Date.today()));
    }
}