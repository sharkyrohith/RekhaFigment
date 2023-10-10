/********************************************************************************************************************
* @author Sriram
* @date 11/01/2021
*
* @group Merchant Services
*
* @description Helper class for Opportunity
*
**************************************************************************************************************************************/
public class CDdMxSxOpportunityHelper {
    /**
     * Define class variables here
     */
    private Map<Id, Opportunity> opportunities;
    private Map<Id, Id> parentAccountIdByOpportunityId;
    private Map<Id, Id> storeAccountIdByOpportunityId;
    private Map<Id, Id> parentAccountIdByStoreAccountId;
    private Map<Id, List<OpportunityLineItem>> opportunityLineItemsByOpportunityId;
    private Map<Id, List<OrderItem>> orderItemsByOpportunityId;
    private Map<Id, List<Case>> casesByOpportunityId;
    /**
     * @description Single argument constructor
     * @param Set<Id> opportunityIds - Collection of Opportunity Ids
     */
    public CDdMxSxOpportunityHelper(Set<Id> opportunityIds) {
        this.setOpportunities(opportunityIds);
    }
    /**
     * @description Query and set the following instance variables
     * 1. this.opportunities - A Collection of Opportunities found for the input Opportunity Record Identifiers
     * 2. this.opportunityLineItemsByOpportunityId - A collection of Opportunity Products associated with the Opportunity
     * 3. this.orderItemsByOpportunityId - A collection of Order Products associated with the Opportunity (linked via Primary Quote on the Opportunity)
     * @param Set<Id> opportunityIds - Collection of Opportunity Ids
     * @return void
     */
    private void setOpportunities(Set<Id> opportunityIds){
        this.opportunities = new Map<Id, Opportunity>();
        this.parentAccountIdByOpportunityId = new Map<Id, Id>();
        this.storeAccountIdByOpportunityId = new Map<Id, Id>();
        this.parentAccountIdByStoreAccountId = new Map<Id, Id>();
        this.opportunityLineItemsByOpportunityId =  new Map<Id, List<OpportunityLineItem>>();
        this.orderItemsByOpportunityId = new Map<Id, List<OrderItem>>();
        this.casesByOpportunityId = new Map<Id, List<Case>>();
        Map<Id, Id> primaryQuoteIdByOpportunityId = new Map<Id, Id>();
        /*for (Opportunity o :[   SELECT Id, RecordTypeId, Type, StageName, SBQQ__PrimaryQuote__c, CreatedBy.Id, CloseDate,
                                AccountId, Account.RecordTypeId, Account.ParentId, Account.Parent.RecordTypeId, Account.Parent.Deck_Rank__c,
                                Account.Is_Test_Store__c, Account.Business_ID__c, Account.Deck_Rank__c,
                                OwnerId, Decision_Maker__c, Store_Manager__c, Bulk_Activation__c, Notes__c,
                                PactSafe_Contract_Type__c,
                                (SELECT Id, Name, Product2Id, Product2.Id, Product2.Family, Product2.Name, Product2.Priority_for_Activation__c, Quantity, Delay_after_Activation_days__c,Length_of_Term__c FROM OpportunityLineItems),
                                (SELECT Id, RecordTypeId, AccountId, Opportunity_Name__c, ProductId
                                FROM Cases__r ORDER BY CreatedDate DESC, ClosedDate DESC NULLS FIRST)
                                FROM Opportunity
                                WHERE Id IN :opportunityIds
                                AND RecordTypeId IN :CDdMxSxConstants.MXSX_OPPORTUNITY_RECORD_TYPE_IDS
                                AND AccountId != NULL
                                AND Account.Is_Test_Store__c = false
                                AND (Account.ParentId = NULL OR Account.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT OR Account.Parent.RecordTypeId = :CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT)
                                AND Type NOT IN :CDdMxSxConstants.OPPORTUNITY_CLOSED_WON_TYPES_TO_EXCLUDE
                            ]){*/
        for (Opportunity o : OpportunitiesSelector.newInstance().selectOnboardingOpportunitiesWithLineItemsAndCases(opportunityIds)){
            this.opportunities.put(o.Id, o);
            if (o.OpportunityLineItems!=null && !o.OpportunityLineItems.isEmpty()){
                this.opportunityLineItemsByOpportunityId.put(o.Id, o.OpportunityLineItems);
            }
            if (o.Cases__r!=null && !o.Cases__r.isEmpty()){
                this.casesByOpportunityId.put(o.Id, o.Cases__r);
            }
            if (String.isNotBlank(o.SBQQ__PrimaryQuote__c)){
                primaryQuoteIdByOpportunityId.put(o.Id, o.SBQQ__PrimaryQuote__c);
            }
            if (CDdMxSxConstants.MXSX_STORE_ACCOUNT_RECORD_TYPE_IDS.contains(o.Account.RecordTypeId)){
                this.storeAccountIdByOpportunityId.put(o.Id, o.AccountId);
                if (String.isNotBlank(o.Account.ParentId)){
                    this.parentAccountIdByOpportunityId.put(o.Id, o.Account.ParentId);
                    this.parentAccountIdByStoreAccountId.put(o.AccountId, o.Account.ParentId);
                }
            }
            if (CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_PARENT_ACCOUNT.equals(o.Account.RecordTypeId)){
                this.parentAccountIdByOpportunityId.put(o.Id, o.AccountId);
            }
        }
        if (!primaryQuoteIdByOpportunityId.isEmpty()){
            /*for (Order o : [    SELECT Id, OpportunityId, SBQQ__Quote__c,
                                (SELECT Id, OrderId, Quantity, SBQQ__OrderedQuantity__c,
                                SBQQ__QuoteLine__r.SBQQ__StartDate__c, SBQQ__QuoteLine__r.Trial_Start_Date__c,
                                SBQQ__QuoteLine__r.SBQQ__Quote__r.Contract_Signed_Date__c,
                                Product2Id, Product2.Id, Product2.Family, Product2.Name, Product2.Priority_for_Activation__c,
                                Delay_after_Activation_days__c,Length_of_Term__c
                                FROM OrderItems)
                                FROM Order
                                WHERE OpportunityId IN :primaryQuoteIdByOpportunityId.keySet()
                            ]){*/
            for (Order o : OrdersSelector.newInstance().selectOrderAndOrderItemsByOpportunityId(primaryQuoteIdByOpportunityId.keySet())){
                if (primaryQuoteIdByOpportunityId.get(o.OpportunityId).equals(o.SBQQ__Quote__c) && o.OrderItems!=null && !o.OrderItems.isEmpty()){
                    this.orderItemsByOpportunityId.put(o.OpportunityId, o.OrderItems);
                }
            }
        }
    }
    /**
     * @description Return the Opportunity record for the input Opportunity Identifier
     * @param Id opportunityId
     * @return Opportunity
     */
    public Opportunity getOpportunity(Id opportunityId){
        return this.opportunities.containsKey(opportunityId) ? this.opportunities.get(opportunityId) : null;
    }
    /**
     * @description Does the input Opportunity Id have a Parent Account Id?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasParentAccountId(Id opportunityId){
        return this.parentAccountIdByOpportunityId.containsKey(opportunityId);
    }
    /**
     * @description Return the Parent Account Id for the input Opportunity Id
     * @param Id opportunityId
     * @return Id - Return the Parent Account Id
     */
    public Id getParentAccountId(Id opportunityId){
        return this.hasParentAccountId(opportunityId) ? this.parentAccountIdByOpportunityId.get(opportunityId) : null;
    }
    /**
     * @description Does the input Opportunity Id have a Store Account Id? (Marketplace/Enterprise Marketplace)
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasStoreAccountId(Id opportunityId){
        return this.storeAccountIdByOpportunityId.containsKey(opportunityId);
    }
    /**
     * @description Return the Store Account Id for the input Opportunity Id
     * @param Id opportunityId
     * @return Id - Return the Store Account Id
     */
    public Id getStoreAccountId(Id opportunityId){
        return this.hasStoreAccountId(opportunityId) ? this.storeAccountIdByOpportunityId.get(opportunityId) : null;
    }
    /**
     * @description Return all the Parent Account Ids related to Opportunities
     * @param
     * @return Set<Id> - Return a Collection of Parent Account Ids
     */
    public Set<Id> getParentAccountIds(){
        return new Set<Id>(this.parentAccountIdByOpportunityId.values());
    }
    /**
     * @description Is the opportunity closed won?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean isClosedWon(Id opportunityId){
        return opportunities.containsKey(opportunityId)
                &&
                CDdMxSxConstants.OPPORTUNITY_STAGE_CLOSED_WON.equals(opportunities.get(opportunityId).StageName);
    }
    /**
     * @description Return the close date for this opportunity
     * @param Id opportunityId
     * @return Datetime
     */
    public Datetime getCloseDate(Id opportunityId){
        return opportunities.containsKey(opportunityId) ? opportunities.get(opportunityId).CloseDate : null;
    }
    /**
     * @description Is the opportunity self serve?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean isSelfServe(Id opportunityId){
        return  opportunities.containsKey(opportunityId) &&
                CDdMxSxOpportunityHelper.isSelfServe(opportunities.get(opportunityId));
    }
    /**
     * @description Return the segment (Enterprise or Local) for the associated account on the Opportunity
     * @param Id opportunityId
     * @return String
     */
    public String getSegment(Id opportunityId){
        if (!this.opportunities.containsKey(opportunityId)) { return null; }
        Opportunity o = this.opportunities.get(opportunityId);
        Boolean isEnterpriseSegment = false;
        if (CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_ENTERPRISE_MARKETPLACE.equals(o.RecordTypeId)
            ||
            CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(o.Account.RecordTypeId)
            ||
            new Set<String>{CDdMxSxConstants.DECK_RANK_ACE_OF_SPADES, CDdMxSxConstants.DECK_RANK_KING_OF_SPADES}.contains(o.Account.Deck_Rank__c)){
            isEnterpriseSegment = true;
        }
        if (!isEnterpriseSegment && String.isNotBlank(o.Account.ParentId)){
            isEnterpriseSegment = (String.isNotBlank(o.Account.Parent.Deck_Rank__c) && o.Account.Parent.Deck_Rank__c.contains(CDdMxSxConstants.DECK_RANK_OF_SPADES));
        }
        return isEnterpriseSegment ? CDdMxSxConstants.SEGMENT_ENTERPRISE : CDdMxSxConstants.SEGMENT_LOCAL;
    }
    /**
     * @description Does Opportunity have products?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasProducts(Id opportunityId){
        return (opportunities.containsKey(opportunityId)
                    &&
                (opportunityLineItemsByOpportunityId.containsKey(opportunityId) || orderItemsByOpportunityId.containsKey(opportunityId)));
    }
    /**
     * @description Does Opportunity have CPQ products?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasCPQProducts(Id opportunityId){
        return this.hasProducts(opportunityId) && orderItemsByOpportunityId.containsKey(opportunityId);
    }
    /**
     * @description Does Opportunity have Legacy products?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasLegacyProducts(Id opportunityId){
        return this.hasProducts(opportunityId) && opportunityLineItemsByOpportunityId.containsKey(opportunityId);
    }

    /**
     * @description get CPQ Products for Opportunity
     * @param Id opportunityId
     * @return List<OrderItem>
    */
    public List<OrderItem> getCPQProducts(Id opportunityId){
        if(hasCPQProducts(opportunityId)){
            return orderItemsByOpportunityId.get(opportunityId);
        }
        return new List<OrderItem>();
    }
    /**
     * @description Get CPQ Storefront Package
     * NOTE: Returns null, if CPQ Storefront Package is not found
     * @param Id opportunityId
     * @return OrderItem
     */
    public OrderItem getCPQStorefrontPackage(Id opportunityId){
        if (!this.hasProducts(opportunityId) || !this.hasCPQProducts(opportunityId)) return null;
        for (OrderItem oi : this.orderItemsByOpportunityId.get(opportunityId)){
            if (oi.Product2Id!=null && oi.Product2.Name.contains(CDdMxSxConstants.STOREFRONT_CONTAINS_KEY_BUNDLE_NAME_FOR_CPQ)){
                return oi;
            }
        }
        return null;
    }
    /**
     * @description Get Legacy Storefront Package
     * NOTE: Returns null, if Legacy Storefront Package is not found
     * @param Id opportunityId
     * @return OpportunityLineItem
     */
    public OpportunityLineItem getLegacyStorefrontPackage(Id opportunityId){
        if (!this.hasProducts(opportunityId) || !this.hasLegacyProducts(opportunityId)) return null;
        for (OpportunityLineItem oli : this.opportunityLineItemsByOpportunityId.get(opportunityId)){
            if (oli.Product2Id!=null && oli.Product2.Name.contains(CDdMxSxConstants.STOREFRONT_CONTAINS_KEY_BUNDLE_NAME_FOR_LEGACY)){
                return oli;
            }
        }
        return null;
    }
    /**
     * @description Does Opportunity have Storefront Pricing?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasStorefrontPricing(Id opportunityId){
        if (!this.hasProducts(opportunityId)) return false;
        return (this.hasCPQProducts(opportunityId))
                ?   (getCPQStorefrontPackage(opportunityId) != null)
                :   (getLegacyStorefrontPackage(opportunityId) != null);
    }
    /**
     * @description Does Opportunity have Storefront Pricing?
     * @param Id opportunityId
     * @return Boolean
     */
    public Product2 getStorefrontPackage(Id opportunityId){
        if (!this.hasProducts(opportunityId) || !this.hasStorefrontPricing(opportunityId)) return null;
        if (this.hasCPQProducts(opportunityId)){
            OrderItem sfPackage = getCPQStorefrontPackage(opportunityId);
            if (sfPackage != null){
                return new Product2(Id = sfPackage.Product2Id, Family = sfPackage.Product2.Family, Name = sfPackage.Product2.Name, Priority_for_Activation__c = sfPackage.Product2.Priority_for_Activation__c);
            }
        } else {
            OpportunityLineItem sfPackage = getLegacyStorefrontPackage(opportunityId);
            if (sfPackage != null){
                return new Product2(Id = sfPackage.Product2Id, Family = sfPackage.Product2.Family, Name = sfPackage.Product2.Name, Priority_for_Activation__c = sfPackage.Product2.Priority_for_Activation__c);
            }
        }
        return null;
    }
    /**
     * @description Does Opportunity have Net-New Storefront Pricing?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasNetNewStorefrontPricing(Id opportunityId){
        if (!this.hasProducts(opportunityId)) return false;
        return (this.hasCPQProducts(opportunityId))
                ?   (getCPQStorefrontPackage(opportunityId) != null && getCPQStorefrontPackage(opportunityId).SBQQ__OrderedQuantity__c >= 1)
                :   (getLegacyStorefrontPackage(opportunityId) != null && getLegacyStorefrontPackage(opportunityId).Quantity >= 1);
    }
    /**
     * @description Does Opportunity have Re-negotiated Storefront Pricing?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasRenegotiatedStorefrontPricing(Id opportunityId){
        if (!this.hasProducts(opportunityId)) return false;
        return (this.hasCPQProducts(opportunityId))
                ?   (getCPQStorefrontPackage(opportunityId) != null && getCPQStorefrontPackage(opportunityId).SBQQ__OrderedQuantity__c <= 0)
                :   (getLegacyStorefrontPackage(opportunityId) != null && getLegacyStorefrontPackage(opportunityId).Quantity <= 0);
    }
    /**
     * @description Does Opportunity have associated Case records?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasCases(Id opportunityId){
        return (this.opportunities.containsKey(opportunityId) && this.casesByOpportunityId.containsKey(opportunityId));
    }
    /**
     * @description Get Case records for input Opportunity Id, Case Record Type Id and optional input Product Id
     * @param Id opportunityId (required)
     * @param Id caseRecordTypeId (required)
     * @param Id productId (optional)
     * @return List<Case> - Return a Collection of Case records
     */
    public List<Case> getCases(Id opportunityId, Id caseRecordTypeId, Id productId){
        List<Case> casesForRecordTypeId = new List<Case>();
        if (this.hasCases(opportunityId)){
            for (Case c : this.casesByOpportunityId.get(opportunityId)){
                if (c.RecordTypeId.equals(caseRecordTypeId) && (String.isBlank(productId) || productId.equals(c.ProductId))){
                    casesForRecordTypeId.add(c);
                }
            }
        }
        return casesForRecordTypeId;
    }
    /**
     * @description Does Opportunity have Post Sale Activation Cases?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasPostSalesActivationCases(Id opportunityId){
        return !this.getCases(opportunityId, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POST_SALE_ACTIVATIONS, null).isEmpty();
    }
    /**
     * @description Does a Post Sale Activation Case exist for a Storefront Bundle that is sold on the Opportunity record?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean hasPostSalesActivationCaseForStorefrontBundle(Id opportunityId){
        Product2 storefrontPackage = this.getStorefrontPackage(opportunityId);
        return storefrontPackage!=null && !getCases(opportunityId, CDdMxSxConstants.RECORD_TYPE_ID_CASE_POST_SALE_ACTIVATIONS, storefrontPackage.Id).isEmpty();
    }
    /**
     * @description Is pactsafe contract type 'SSMO Sign Up Sheet'?
     * @param Id opportunityId
     * @return Boolean
     */
    public Boolean isPactSafeContractTypeSSMOSignUpSheet(Id opportunityId){
        return opportunities.containsKey(opportunityId)
                &&
                CDdMxSxConstants.PACTSAFE_CONTRACT_TYPE_SSMO_SIGN_UP_SHEET.equals(opportunities.get(opportunityId).PactSafe_Contract_Type__c);
    }

    /**
     * @description Is the opportunity being updated by Integration user? Currenlty checking Mulesoft Integration User only.
     * Other users can be added if needed.
     * @return Boolean
     */
    public Boolean isCurrentUserSelfServe(){
        return UserInfo.getUserId() == Id.valueOf(CDdCustomMetadata.getIdValueFor('Mulesoft_Integration_User'));
    }
    /**
     * @description Is the opportunity is of Small and Medium Business (Not Enterprise)
     * @return Boolean
    */
    public Boolean isSMB(Id opportunityId){
        return (opportunities.containsKey(opportunityId)
                && isSMB(opportunities.get(opportunityId)));
    }
    /**
     * @description Is the opportunity of Type Change of Ownership
     * @param Opportunity opportunity
     * @return Boolean
    */
    public Boolean isOpportunityofTypeChangeofOwnership(Id opportunityId){
        return (opportunities.containsKey(opportunityId)
                && isOpportunityofTypeChangeofOwnership(opportunities.get(opportunityId)));
    }
    /**
     * @description Is the opportunity of Small and Medium Business (Not Enterprise)
     * @param Opportunity opportunity
     * @return Boolean
    */
    public static Boolean isSMB(Opportunity opportunity){
        if (CDdMxSxConstants.RECORD_TYPE_ID_OPPORTUNITY_MARKETPLACE.equals(opportunity.RecordTypeId)
            && String.isNotBlank(opportunity.AccountId)
            && !CDdMxSxConstants.RECORD_TYPE_ID_ACCOUNT_ENTERPRISE_MARKETPLACE.equals(opportunity.Account.RecordTypeId)
            && !CDdMxSxConstants.DECK_RANKS_TO_EXCLUDE_FOR_SMB.contains(opportunity.Account.Deck_Rank__c)
            && !CDdMxSxConstants.DECK_RANKS_TO_EXCLUDE_FOR_SMB.contains(opportunity.Account.Launch_Deck_Rank__c)){
                return true;
        }
        return false;
    }
    /**
     * @description Is the opportunity of Type Change of Ownership
     * @param Opportunity opportunity
     * @return Boolean
    */
    public static Boolean isOpportunityofTypeChangeofOwnership(Opportunity opportunity){
        if (String.isNotBlank(opportunity.Type)
            && CDdMxSxConstants.OPPORTUNITY_TYPE_CHANGE_OF_OWNERSHIP.equals(opportunity.Type)){
                return true;
        }
        return false;
   }
    /**
     * @description Is the opportunity self serve?
     * @param Opportunity opportunity
     * @return Boolean
     */
    public static Boolean isSelfServe(Opportunity opportunity){
        return isUserSelfServe(opportunity.CreatedById) ||
                (CDdMxSxConstants.MULESOFT_INTEGRATION_USER_ID.equals(opportunity.CreatedById) &&
                 CDdCoreConstants.LEADSOURCE_DETAIL_SSMO.equals(opportunity.Lead_Source_Detail__c));
    }

    /**
        @author: Dan Thoreson
        @date: 11-Jan-2023
        @description: This method is used for capturing the User types that are used in Self-Serve Opportunities.
    **/
    public static Boolean isUserSelfServe(Id userId) {
        return  CDdMxSxConstants.SELF_SERVE_USER_IDS.contains(userId) ||
                CDdMxSxConstants.NINTEX_INTEGRATION_USER_ID.equals(userId) ||
                CDdMxSxConstants.FORMSTACK_INTEGRATION_USER_ID.equals(userId) ||
                CDdMxSxConstants.MULESOFT_INTEGRATION_USER_ID.equals(userId);
    }

    /**
        @author: Dan Thoreson
        @date: 09-Jan-2023
        @description: Filters an inputted Set of Opportunities, returning only those which are Storefront Opportunities.
                      A "Storefront Opportunity" has a child Order and a grandchild OrderItem with a Product2.Name containing
                      "Storefront Package".
    **/
    public static Set<Id> getStorefrontOpportunities(Set<Id> opportunityIds) {
        Set<Id> storefrontOpps = new Set<Id>();

        if(!opportunityIds.isEmpty()) {
            for(OrderItem thisItem : OrderItemsSelector.newInstance().selectItemsWithStorefrontProducts(opportunityIds)) {
                storefrontOpps.add(thisItem.Order.OpportunityId);
            }
        }

        return storefrontOpps;
    }
    /**
     * @description Is the Opportuntiy Platform of Type Caviar
     * Platform__c contains: Caviar 0R Caviar and Doordash
     * @param Id opportunityId
     * @return Boolean
    */
    public Boolean isCaviarOpportunity(Id opportunityId){
        if (!opportunities.containsKey(opportunityId) || String.isBlank(opportunities.get(opportunityId).Platform__c)){
            return false;
        }else {
            return CDdMxSxConstants.OPPORTUNITY_PLATFORMS_CONTAINS_CAVIAR.contains(opportunities.get(opportunityId).Platform__c);
        }
    }
    /**
     * @description get the Opportunity Platform
     * @param Id opportunityId
     * @return String
    */
    public String getPlatform(Id opportunityId){
        if (!opportunities.containsKey(opportunityId) || String.isBlank(opportunities.get(opportunityId).Platform__c)){
            return null;
        }else {
            return opportunities.get(opportunityId).Platform__c;
        }
    }
    /**
     * @description get OrderLineItems For Products Of Ads And Promo Families
     * @param Id opportunityId
     * @return List<OrderItem>
    */
    public List<OrderItem> getOrderItemsForProductsOfAdsAndPromoFamilies(Id opportunityId){
        List<OrderItem> orderItems = new List<OrderItem>();
        Set<String> PRODUCT_FAMILIES_ADS_PROMOS =  new Set<String>(CDdMxSxConstants.PRODUCT_FAMILIES_ADS_PROMOS);
        if (this.opportunities.containsKey(opportunityId) && this.orderItemsByOpportunityId.containsKey(opportunityId)){
            for (OrderItem oi : this.orderItemsByOpportunityId.get(opportunityId)) {
                if(PRODUCT_FAMILIES_ADS_PROMOS.contains(oi.Product2.Family)){
                    orderItems.add(oi);
                }
            }
        }
        return !orderItems.isEmpty()? orderItems : null;
    }
}