/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/14/2021
*
* @group Fee Onboarding CPQ
*
* @description Service class for Fee Onboarding that supports CPQ Model for Opportunity 
**************************************************************************************************************************************/
public class CDdFeeOnboardingCPQService {
    private static final Set<String> FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS = CDdFeeOnboardingCPQProgramFeeHelper.getProductDDCustomIds();
    private static final List<String> FEE_ONBOARDING_ORDER_ITEM_FEE_FIELDS = new List<String>(CDdFeeOnboardingCPQProgramFeeHelper.getOrderItemFeeFields());
    private static final String SOQL_QUERY_ORDER_ITEM_SELECT 
                                = 'SELECT Id, Order.Account.Restaurant_Id__c, '
                                + 'Order.Account.RealZip__RealZip__r.Time_Zone_GMT_Offset__c, '
                                + 'Order.Account.BillingCountryCode, '
                                + 'Order.OpportunityId, Product2.DD_Custom_ID__c, '
                                + 'SBQQ__RequiredBy__r.Product2.Package_Name__c, '
                                + 'LastModifiedDate, '
                                + String.join(FEE_ONBOARDING_ORDER_ITEM_FEE_FIELDS, ',');
    private static final String SOQL_QUERY_ORDER_ITEM_FROM = ' FROM OrderItem ';
    private static final String SOQL_QUERY_ORDER_ITEM_WHERE 
                                = ' WHERE Order.OpportunityId = :opportunityId '
                                + ' AND Order.SBQQ__Quote__c = :primaryQuoteId '
                                + ' AND Product2.DD_Custom_ID__c IN :FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS ';
    private static final String SOQL_QUERY_ORDER_ITEM_STRING = SOQL_QUERY_ORDER_ITEM_SELECT
                                                + SOQL_QUERY_ORDER_ITEM_FROM
                                                + SOQL_QUERY_ORDER_ITEM_WHERE;
    private Id opportunityId;
    private Id primaryQuoteId;
    private List<OrderItem> orderItems;
    /**
     * @description Single argument constructor
     * @param Id input opportunity Id
     * @param Id input primary quote Id
     * @return
     */ 
    public CDdFeeOnboardingCPQService(Id opportunityId, Id primaryQuoteId){
        this.opportunityId = opportunityId;
        this.primaryQuoteId = primaryQuoteId;
        this.orderItems = new List<OrderItem>();
        this.orderItems.addAll(getOrderItems());
    }
    /**
     * @description Return a Collection of fee onboarding program objects for the Opportunity and Primary Quote
     * @param -
     * @return List<CDdFeeOnboardingProgramObject> Return a Collection of fee onboarding program objects
     */     
    public List<CDdFeeOnboardingProgramObject> getProgramObjects(){
        return new CDdFeeOnboardingCPQProgramFeeHelper(this.orderItems).getProgramObjects();
    }    
    /**
     * @description Return a Collection of fee onboarding program objects restricted to the input fee Ids
     * Note : If feeIds is NULL, there will be no restriction applied to the program and fee objects
     * @param List<Id> Restrict the program objects to these feeIds 
     * @return List<CDdFeeOnboardingProgramObject> Return a Collection of fee onboarding program objects
     */     
    public List<CDdFeeOnboardingProgramObject> getProgramObjects(List<Id> feeIds){
        return new CDdFeeOnboardingCPQProgramFeeHelper(this.orderItems, feeIds).getProgramObjects();
    }
    /**
     * @description Get the order item records associated with Fee Onboarding products
     * @param 
     * @return List<OrderItem> Return a Collection of Order Item records
     */
    private List<OrderItem> getOrderItems(){
        List<OrderItem> orderItems = new List<OrderItem>();
        for (OrderItem orderItem : Database.query(SOQL_QUERY_ORDER_ITEM_STRING)) {
            orderItems.add(orderItem);
        }
        return orderItems;        
    }
}