/********************************************************************************************************************
* @author Sriram (Perficient, Inc.)
* @date 05/12/2021
*
* @group Fee Onboarding CPQ
*
* @description  This class reads the Fee Onboarding CPQ custom metadata for Programs and Fees
*               - Parent Fee_Onboarding_CPQ_Program__mdt captures the various programs available for Fee Onboarding
*               - Child Fee_Onboarding_CPQ_Fee__mdt participates in a one-to-many relationship with parent Fee_Onboarding_CPQ_Program__mdt
*               - Fee_Onboarding_CPQ_Fee__mdt has additional fields relevant to Order Item record 
*                   a) Order Item Fee Field, which has the field api name that contains the value for Fee Rate or Flat Fee
*                   c) Order Item Fee Start Date Field, which has the field api date field
*                       for when the fee starts for a specific Fee Onboarding Program
*                   d) Order Item Fee End Date Field, which has the field api date field
*                       for when the fee ends for a specific Fee Onboarding Program
*               Usage:
*                   Instantiate this class with a Collection Of Order Item records 
                        (Order items should ideally, 
                            belong to an Order associated with a Primary Quote found on the Opportunity record
                            have a Product DD Custom Id available on the product record referenced by the Order Item record)
                    Instantiate this class with a Collection of fee Ids
                        to restrict the Program and Fee objects to the specific fee ids in the input
                    Use 'getProgramObjects' method 
                        to request for a Collection of objects of type CDdFeeOnboardingProgramObject
**************************************************************************************************************************************/
public class CDdFeeOnboardingCPQProgramFeeHelper {
    private static final List<Fee_Onboarding_CPQ_Program__mdt> FEE_ONBOARDING_CPQ_PROGRAMS;
    private static Set<String> FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS;
    private static Set<String> ORDER_ITEM_FEE_FIELDS;
    private Map<String, OrderItem> orderItems;
    // If restrictedFeeIds is populated (i.e. not null), then the 
    // Program and Fee objects returned to caller will only include the ones as found in the restricted fee Ids Collection 
    private Set<Id> restrictedFeeIds;
    static {
        FEE_ONBOARDING_CPQ_PROGRAMS = new List<Fee_Onboarding_CPQ_Program__mdt>();
        FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS = new Set<String>();
        ORDER_ITEM_FEE_FIELDS = new Set<String>();
        for (Fee_Onboarding_CPQ_Program__mdt p : [SELECT Id, MasterLabel, DeveloperName, Is_Active__c, Sequence__c, Api_Type__c,
                                            Audience__c, Channel__c, Experience__c, Fulfillment_Type__c, Product_DD_Custom_ID__c,
                                            (SELECT Id, MasterLabel, DeveloperName, Is_Active__c, Sequence__c,
                                            Fee_Display_Name__c, Fee_Name__c, Fee_Rate_Charging_Target__c,
                                            Fee_Type__c, Is_Fee_Rate__c, Is_Trial_Fee__c, Product_DD_Custom_ID__c, Package_Name__c,
                                            Order_Item_Fee_Field__c, Order_Item_Fee_Start_Date_Field__c, Order_Item_Fee_End_Date_Field__c 
                                            FROM Fee_Onboarding_CPQ_Fees__r
                                            WHERE Is_Active__c = TRUE
                                            ORDER BY Sequence__c ASC
                                            )
                                            FROM Fee_Onboarding_CPQ_Program__mdt
                                            WHERE Is_Active__c = TRUE
                                            ORDER BY Sequence__c ASC]){
            FEE_ONBOARDING_CPQ_PROGRAMS.add(p);
            FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS.add(p.Product_DD_Custom_ID__c);
            for (Fee_Onboarding_CPQ_Fee__mdt f : p.Fee_Onboarding_CPQ_Fees__r){
                FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS.add(f.Product_DD_Custom_ID__c);
                ORDER_ITEM_FEE_FIELDS.add(f.Order_Item_Fee_Field__c);
                ORDER_ITEM_FEE_FIELDS.add(f.Order_Item_Fee_Start_Date_Field__c);
                if (String.isNotBlank(f.Order_Item_Fee_End_Date_Field__c)){
                    ORDER_ITEM_FEE_FIELDS.add(f.Order_Item_Fee_End_Date_Field__c);
                }
            }
        }
    }
    /**
     * @description Single argument constructor
     * Re-organize the input collection of order item records as a Map with key as Product DD Custom Id
     * @param List<OrderItem> Collection of Order Item records
     */     
    public CDdFeeOnboardingCPQProgramFeeHelper(List<OrderItem> inputOrderItems){
        this(inputOrderItems, null);
    }
    /**
     * @description 2 argument constructor
     * Using this constructor will narrow down the program objects and fee objects to the input fee ids
     * Note : If feeIds is NULL, there will be no restriction applied to the program and fee objects
     * @param List<OrderItem> Collection of Order Item records
     * @param List<Id> the feeIds 
     */     
    public CDdFeeOnboardingCPQProgramFeeHelper(List<OrderItem> inputOrderItems, List<Id> feeIds){
        this.orderItems = new Map<String, OrderItem>();
        for (OrderItem oi : inputOrderItems){
            this.orderItems.put(oi.Product2.DD_Custom_ID__c, oi);
        }        
        this.restrictedFeeIds = (feeIds!=null ? new Set<Id>(feeIds) : null);
    }        
    /**
     * @description Return the Coolection of Product DD Custom Ids 
     *              as found configured across Program and Fee Custom Metadata records
     * @param -
     * @return Set<String> Collection of Product DD Custom Ids
     */     
    public static Set<String> getProductDDCustomIds(){
        return FEE_ONBOARDING_PRODUCT_DD_CUSTOM_IDS;
    }
    /**
     * @description Return the Order Item Fee related Field API names as found configured in the Fee Custom Metadata records
     * @param -
     * @return Set<String> Collection of Order Item field API Names
     */      
    public static Set<String> getOrderItemFeeFields(){
        return ORDER_ITEM_FEE_FIELDS;
    }
    /**
     * @description Return a Collection of fee onboarding program objects
     * Note: Program that does not have any fees, will not be added to the Program Object Collection
     * @param -
     * @return List<CDdFeeOnboardingProgramObject> Return a Collection of fee onboarding program objects
     */     
    public List<CDdFeeOnboardingProgramObject> getProgramObjects(){
        List<CDdFeeOnboardingProgramObject> programObjects = new List<CDdFeeOnboardingProgramObject>();
        for (Fee_Onboarding_CPQ_Program__mdt programMdtRec : FEE_ONBOARDING_CPQ_PROGRAMS){
            if (this.orderItems.containsKey(programMdtRec.Product_DD_Custom_ID__c)){
                CDdFeeOnboardingProgramObject programObject = getProgramObject(programMdtRec);
                if (!programObject.fees.isEmpty()){
                    programObjects.add(programObject);
                }
            }
        }
        return programObjects;
    }
    /**
     * @description Return an instance of a fee onboarding program object
     * @param Fee_Onboarding_CPQ_Program__mdt program custom metadata record
     * @return CDdFeeOnboardingProgramObject Return the fee onboarding program object
     */         
    private CDdFeeOnboardingProgramObject getProgramObject(Fee_Onboarding_CPQ_Program__mdt programMdtRec){
        CDdFeeOnboardingProgramObject programObj = new CDdFeeOnboardingProgramObject(programMdtRec, this.orderItems.get(programMdtRec.Product_DD_Custom_ID__c));
        for (Fee_Onboarding_CPQ_Fee__mdt feeMdtRec : programMdtRec.Fee_Onboarding_CPQ_Fees__r){
            if (this.orderItems.containsKey(feeMdtRec.Product_DD_Custom_ID__c)){
                OrderItem feeOrderItem = this.orderItems.get(feeMdtRec.Product_DD_Custom_ID__c);
                if (hasFee(feeMdtRec, feeOrderItem)){
                    programObj.addFee(feeMdtRec, 
                                        feeOrderItem, 
                                        getFeeValue(feeMdtRec, feeOrderItem),
                                        getFeeStartDate(feeMdtRec, feeOrderItem),
                                        getFeeEndDate(feeMdtRec, feeOrderItem)
                                    );
                }
            }
        }
        return programObj;
    }
    /**
     * @description Does the Order Item have a valid fee based on the configured fee custom metadata?
     * a) Process fee, if there is no restricted fee ids OR if the non-null restricted fee ids contains the input fee id
     * b) Configured Fee Product DD Custom Id should match with Product DD Custom Id found on the product of the Order Item record
     * c) If Fee is configured for a package name
     *    Then
     *      Configured package name for fee should match with the package bundle name the order item belongs to
     * d) If Fee is configured as a trial fee,
     *    Then
     *      Order Item should include the product for a non-expired trial period 
     *      Order Item should have a non-null fee value for the product
     * e) If Fee is configured as a non-trial fee,
     *    Then
     *      Order Item should have a non-null fee value for the product
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @return Boolean - Return true or false
     */     
    private Boolean hasFee(Fee_Onboarding_CPQ_Fee__mdt feeMdtRec, OrderItem orderItem){
        return (    (   this.restrictedFeeIds == null
                        ||  (this.restrictedFeeIds.contains(feeMdtRec.Id))
                    )
                    &&  feeMdtRec.Product_DD_Custom_ID__c.equals(orderItem.Product2.DD_Custom_ID__c)
                    &&  (
                        (String.isBlank(feeMdtRec.Package_Name__c))
                        ||  (String.isNotBlank(feeMdtRec.Package_Name__c) 
                            && orderItem.SBQQ__RequiredBy__r!=null 
                            && orderItem.SBQQ__RequiredBy__r.Product2!=null
                            && feeMdtRec.Package_Name__c.equals(orderItem.SBQQ__RequiredBy__r.Product2.Package_Name__c)
                        )
                    )
                    &&  (
                        (feeMdtRec.Is_Trial_Fee__c && isTrialFee(feeMdtRec, orderItem) && getFeeValue(feeMdtRec, orderItem) != null) 
                        || (!feeMdtRec.Is_Trial_Fee__c && getFeeValue(feeMdtRec, orderItem) != null)
                    )
        );
    }
    /**
     * @description Return the fee value from the order item record
     * Value returned is either the fee rate (percentage) or the flat fee (Decimal)
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @return Decimal - Return the fee value from the order item record
     */     
    private Decimal getFeeValue(Fee_Onboarding_CPQ_Fee__mdt feeMdtRec, OrderItem orderItem){
        Map<String, Object> fieldsToValue = orderItem.getPopulatedFieldsAsMap();
        return fieldsToValue.containsKey(feeMdtRec.Order_Item_Fee_Field__c) 
                    ? (Decimal)fieldsToValue.get(feeMdtRec.Order_Item_Fee_Field__c) 
                    : null;
    }
    /**
     * @description Return the fee start date from the order item record
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @return Date - Return the fee start date
     */    
    private Date getFeeStartDate(Fee_Onboarding_CPQ_Fee__mdt feeMdtRec, OrderItem orderItem){
        return getFeeDate(feeMdtRec.Order_Item_Fee_Start_Date_Field__c, orderItem);
    }
    /**
     * @description Return the fee end date from the order item record
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @return Date - Return the fee end date
     */     
    private Date getFeeEndDate(Fee_Onboarding_CPQ_Fee__mdt feeMdtRec, OrderItem orderItem){
        return getFeeDate(feeMdtRec.Order_Item_Fee_End_Date_Field__c, orderItem);
    }
    /**
     * @description Return the fee date from the order item record
     * @param String  Order Item Field API Name (must be a field of type Date)
     * @param OrderItem order item record
     * @return Date - Return the fee date from the Order Item record
     */     
    private Date getFeeDate(String orderItemFieldAPIName, OrderItem orderItem){
        Map<String, Object> fieldsToValue = orderItem.getPopulatedFieldsAsMap();
        return String.isNotBlank(orderItemFieldAPIName) && fieldsToValue.containsKey(orderItemFieldAPIName) 
                    ? (Date)fieldsToValue.get(orderItemFieldAPIName) 
                    : null;        
    }       
    /**
     * @description Check if the order item record is a trial record
     * 1. Check if trial is applicable for the Fee Custom Metadata record
     * 2. If so, then check if the trial data points for Order item have values in them
     * 3. And finally check if the data point for Order Item fee end date is >= Today
     * Return true if all the above conditions are met
     * @param Fee_Onboarding_CPQ_Fee__mdt fee custom metadata record
     * @param OrderItem order item record
     * @return Boolean - Is the Order Item a trial record? True or False
     */      
    private Boolean isTrialFee(Fee_Onboarding_CPQ_Fee__mdt feeMdtRec, OrderItem orderItem){
        Map<String, Object> fieldsToValue = orderItem.getPopulatedFieldsAsMap();
        return
            feeMdtRec.Is_Trial_Fee__c
            &&
            fieldsToValue.containsKey(feeMdtRec.Order_Item_Fee_Field__c)
            &&
            fieldsToValue.get(feeMdtRec.Order_Item_Fee_Field__c) != null 
            &&
            fieldsToValue.containsKey(feeMdtRec.Order_Item_Fee_Start_Date_Field__c) 
            &&
            fieldsToValue.get(feeMdtRec.Order_Item_Fee_Start_Date_Field__c) != null 
            &&
            fieldsToValue.containsKey(feeMdtRec.Order_Item_Fee_End_Date_Field__c) 
            &&
            fieldsToValue.get(feeMdtRec.Order_Item_Fee_End_Date_Field__c) != null
            &&
            (Date)fieldsToValue.get(feeMdtRec.Order_Item_Fee_End_Date_Field__c) >= System.today()
        ;
    }        
}