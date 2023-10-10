/**
* @author: Cory Bartholomew (ATG)
* @date: 2021-03
* @description: Controller for Create New Quote Button on Opportunity to default data on record creation
*/
public class CDdCreateQuoteFromOppCtrl {
    public Boolean error {get;set;}

    /**
     * @description BZAP-15003: Populates the Drawer_Attributes__c field with the contents of
     *  the 'Standard Line Item Drawer' field set, comma-delimited.
     *
     * @param quotes (List<SBQQ__Quote__c>)
     * @return (String); the comma-delimited list of fields.
     */
    public static String drawer_attributes {
        get {
            if(drawer_attributes == null){
                drawer_attributes = commaDelimit(
                    SObjectType.SBQQ__QuoteLine__c.FieldSets.SBQQ__StandardLineItemDrawer.getFields()
                );
            }

            return drawer_attributes;
        }

        set;
    }

    private string quoteId;
    private ApexPages.StandardController stdController;
    public CDdCreateQuoteFromOppCtrl(ApexPages.StandardController stdController) {
        this.stdController = stdController;
    }

    /** @author: Cory Bartholomew (ATG)
    * @date: 2021-03
    * @description: create a quote and return a user to the Quote Line Editor */
    public Pagereference createQuote(){


        Id oppId = ApexPages.currentPage().getParameters().get('id');
        Opportunity opp = [
            SELECT
                Id,
                AccountId,
                Account.BillingCountry,
                Account.Primary_Merchant_Categories__c,
                Decision_Maker__c,
                Order_Protocol__c,
                Caviar_Order_Protocol__c,
                RecordTypeId,
                RecordType.Name,
                SBQQ__PrimaryQuote__c,
                SBQQ__PrimaryQuote__r.SBQQ__Status__c,
                Type,
                StageName,
                Eligible_Employees__c,
                Shopping_Protocol__c,
                Control_of_Price__c,
                Commission_Calculation_Methodology__c,
                Payment_Protocol__c,
                Legal_Entity__c
            FROM Opportunity
            WHERE Id = :oppId
        ];
        Pricebook2 pricebook = [
            SELECT Id
            FROM Pricebook2
            WHERE IsStandard = true
            LIMIT 1
        ];

        //The first two errors are very similar, so this is an if - else to only show one error.
        if ((opp.StageName == CDdCpqBillingConstants.OPP_STAGENAME_CLOSED_WON) ||
            (opp.StageName == CDdCpqBillingConstants.OPP_STAGENAME_OUT_FOR_SIGNATURE) ||
            (opp.StageName == CDdCpqBillingConstants.OPP_STAGENAME_CONTRACT_SIGNED))
        {
            addErrorToPage(Label.Cannot_Create_Quote_Opp_Stage);
        } else if ((opp.SBQQ__PrimaryQuote__c != null) &&
                   ((opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c == CDdCpqBillingConstants.QUOTE_STATUS_CONTRACT_SIGNED) ||
                    (opp.SBQQ__PrimaryQuote__r.SBQQ__Status__c == CDdCpqBillingConstants.QUOTE_STATUS_OUT_FOR_SIGNATURE)))
        {
            addErrorToPage(Label.Opp_Already_Has_Contract);
        }

        if(opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() && String.isBlank(opp.Type)){
            addErrorToPage(Label.Opp_Type_Must_Have_Value_to_Create_Quote);
        }

        if(String.isBlank(opp.Decision_Maker__c)){
            addErrorToPage(Label.Opp_Decision_Maker_Required_for_Quote);
        }

        //BZAP-18499
        if(opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.doorDashForBusinessId() && opp.Eligible_Employees__c == null){
            addErrorToPage(Label.Opp_Eligible_Employees_Required_for_DDFB_Quote);
        }

        if(opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() && String.isBlank(opp.Order_Protocol__c) && String.isBlank(opp.Caviar_Order_Protocol__c)){
            addErrorToPage(Label.Opp_Order_Protocol_Required);
        }

        //BASD-46361 do not allow quote creation if Shopping Protocol, Control of Price, Payment Protocol and Commission Calculation Methodology are not filled in .
        if(opp.RecordTypeId == CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId() &&
           opp.Legal_Entity__c == 'US - G&C' &&
           opp.Account.BillingCountry == 'United States' &&
           opp.Account.Primary_Merchant_Categories__c != null &&
           opp.Account.Primary_Merchant_Categories__c != 'Prepared Food & Drink (Rx)' &&
           opp.Account.Primary_Merchant_Categories__c != 'Government or Non-Profit' &&
           opp.Account.Primary_Merchant_Categories__c != 'Incumbents' &&
           (
               opp.Shopping_Protocol__c == null ||
               opp.Control_of_Price__c == null ||
               opp.Commission_Calculation_Methodology__c == null ||
               opp.Payment_Protocol__c == null
           )
          ){
            addErrorToPage(Label.Opp_Required_Fields_Marketplace_When_PMC_Not_Null);
          }

        if(this.error == true){
            return null;
        } else {
            //Create quote and set fallback defaults for functionally required values in case the mappings don't exist
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Account__c = opp.AccountId,
                SBQQ__SubscriptionTerm__c = CDdCpqBillingConstants.SUBSCRIPTION_TERM,
                SBQQ__Primary__c = CDdCpqBillingConstants.CREATE_PRIMARY,
                SBQQ__StartDate__c = Date.today(),
                SBQQ__ExpirationDate__c = Date.today().addDays(CDdCpqBillingConstants.EXPIRATION_DAYS),
                SBQQ__Pricebook__c = pricebook.Id,
                SBQQ__PricebookId__c = pricebook.Id,
                // BZAP-15003: Populates the Drawer_Attributes__c field with the contents of
                //  the 'Standard Line Item Drawer' field set, comma-delimited.
                Drawer_Attributes__c = drawer_attributes
            );
            if(!Test.isRunningTest()){
                quote.User_Group__c = setUserGroup(opp);
            }
            insert quote;
            this.quoteId = quote.Id;
            Pagereference returnPage = Page.SBQQ__SB;
            returnPage.getParameters().put('scontrolCaching','1');
            returnPage.getParameters().put('id',this.quoteId);
            returnPage.setRedirect(true);
            return returnPage;
        }
    }

    public Pagereference returnToOpp(){
        Pagereference returnPage = new Pagereference('/' + ApexPages.currentPage().getParameters().get('id'));
        returnPage.setRedirect(true);
        return returnPage;
    }

    public void addErrorToPage(String errorMessage){
        ApexPages.Message msg = new ApexPages.Message(ApexPages.severity.ERROR, errorMessage);
        ApexPages.addMessage(msg);
        this.error = true;
    }

    //Q2C-847 Determine the user group when creating the quote
    public static String setUserGroup(Opportunity opp){
        String userGroup = '';
        User runningUser = getCurrentUser();

        Map<String,QuoteUserGroup__mdt> mapBillingCountryToAllMdt = new Map<String,QuoteUserGroup__mdt>();
        Map<String,QuoteUserGroup__mdt> mapBillingCountryNoSalesMdt = new Map<String,QuoteUserGroup__mdt>();
        //Custom metadata
        List<QuoteUserGroup__mdt> quoteUserGroups = [SELECT Label, BillingCountry__c, OpportunityRecordType__c, SalesRole__c,UserGroup__c FROM  QuoteUserGroup__mdt];
        for(QuoteUserGroup__mdt quoteUserGroup : quoteUserGroups){
            String salesRoleMdt = quoteUserGroup.BillingCountry__c +'--' + quoteUserGroup.OpportunityRecordType__c +'--'+ quoteUserGroup.SalesRole__c;
            String noSaleRoleMdt = quoteUserGroup.BillingCountry__c +'--' + quoteUserGroup.OpportunityRecordType__c;
            if(String.isNotBlank(quoteUserGroup.SalesRole__c)) {
                mapBillingCountryToAllMdt.put(salesRoleMdt, quoteUserGroup) ;
            } else {
                mapBillingCountryNoSalesMdt.put(noSaleRoleMdt, quoteUserGroup) ;
            }
        }

        if(mapBillingCountryToAllMdt.isEmpty() && mapBillingCountryNoSalesMdt.isEmpty()){
            return null;
        }

        String quoteSalesRole = opp.Account.BillingCountry +'--' + opp.RecordType.Name +'--'+ runningUser.Sales_Role__c;
        String quoteNoSalesRole = opp.Account.BillingCountry +'--' + opp.RecordType.Name;
        if(String.isNotBlank(opp.Account.BillingCountry) &&  String.isNotBlank(opp.RecordType.Name) ){
            if(mapBillingCountryToAllMdt.containsKey(quoteSalesRole) && String.isNotBlank(runningUser.Sales_Role__c)) {
                userGroup = mapBillingCountryToAllMdt.get(quoteSalesRole).UserGroup__c;
            }
            else if(mapBillingCountryNoSalesMdt.containsKey(quoteNoSalesRole)) {
                userGroup = mapBillingCountryNoSalesMdt.get(quoteNoSalesRole).UserGroup__c;
            }
        }
        return userGroup;
    }

    public static User getCurrentUser(){
        User u = [SELECT Id, Sales_Role__c FROM User WHERE Id =: UserInfo.getUserId()];
        return u;
    }

    private static String commaDelimit(List<Schema.FieldSetMember> fieldSetMembers){
        String delimited = '';
        if(fieldSetMembers == null || fieldSetMembers.isEmpty()){
            return delimited;
        }

        for(Schema.FieldSetMember currentMember : fieldSetMembers){
            if(delimited != ''){
                delimited += ', ';
            }
            delimited += currentMember.getFieldPath();
        }

        return delimited;
    }
}