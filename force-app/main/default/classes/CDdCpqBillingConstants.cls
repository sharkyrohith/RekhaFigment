/**
* @author: Cory Bartholomew (ATG)
* @date: 2021-03    
* @description: Constants that are shared accross CPQ and Billing logic              
*/ 
public class CDdCpqBillingConstants {
    //The Opportunity record types that are enabled for CPQ logic
    public static final Set<Id> CPQ_ENABLED_OPP_RECORD_TYPES = new Set<Id>{
        CDdSchemaUtils.OPPORTUNITY_RT.mlInsideSalesId(),
        CDdSchemaUtils.OPPORTUNITY_RT.postSaleId(),
        CDdSchemaUtils.OPPORTUNITY_RT.merchantPromotionId()
    };

    public static final String QUOTE_LINE_EDITOR_BASE_URL = '/apex/sbqq__sb?scontrolCaching=1&id=';

    //Quote create defualts
    public static final Integer EXPIRATION_DAYS = 30;
    public static final Integer SUBSCRIPTION_TERM = 12;
    public static final Boolean CREATE_PRIMARY = true;
    
    public static final Set<String> FORMSTACK_PRODUCT_CODES = new Set<String>{
        'MKTPKG-0000106',
        'MKTPKG-0000110',
        'MKTPL-0000102', 
        'MKTPL-0000103',
        'MKTPL-0000106',
        'MKTPL-0000107',
        'MKTPL-0000108', 
        'MKTPL-0000111', 
        'MKTPL-0000114', 
        'MKTPL-0000119',
        'MKTPL-0000124',
        'MKTPL-0000134',
        'MKTPL-0000146', 
        'MKTPL-0000149'  
    };
    
    public static final String DEAFUALT_PACTSAFE_AGREEMENT_TYPE = 'US Paper Agreement';
    public static final String STATUS_OK = 'Success';
    public static final String STATUS_ERROR = 'Error';

    //Opportunity Platform
    public static final String OPP_PLATFORM_DOORDASH = 'DoorDash';
    public static final String OPP_PLATFORM_CAVIAR = 'Caviar';
    public static final String OPP_PLATFORM_CAVIAR_DOORDASH = 'Caviar and DoorDash';

    //Opportunity Stages
    public static final String OPP_STAGENAME_CLOSED_WON = 'Closed Won'; 
    public static final String OPP_STAGENAME_OUT_FOR_SIGNATURE = 'Out for Signature';
    public static final String OPP_STAGENAME_CONTRACT_SIGNED = 'Contract Signed';

    //Quote Status
    public static final String QUOTE_STATUS_OUT_FOR_SIGNATURE = 'Out for Signature';
    public static final String QUOTE_STATUS_CONTRACT_SIGNED = 'Contract Signed';
    public static final String QUOTE_STATUS_IN_REVIEW = 'In Review';
    public static final String QUOTE_STATUS_APPROVED = 'Approved';
    public static final String QUOTE_STATUS_DRAFT = 'Draft';

    //Product Price Basis
    public static final String PRODUCT_PRICEBASIS_COMMISSION = 'Commission';
    public static final String PRODUCT_PRICEBASIS_FLATCOMMISSION = 'Flat_Commission';
    public static final String PRODUCT_PRICEBASIS_COMMISSIONPLUSFLAT = 'Commission + Flat';


    //Opp Legal Entity
    public static final String US_LEGAL_ENT = 'US';
    public static final String US_LEGAL_ENT_GC = 'US - G&C';
    //Account Billing Country
    public static final String US_BILLING_COUNTRY = 'United States';
    //Opp No_Dashpass_Reason__c
    public static final String OPP_NO_DASHPASS_REASON_NOT_INTERESTED = 'Not interested in giving DoorDash customers free delivery';
    //Opp Order_Protocol__c/Caviar_Order_Protocol from value set
    public static final String OPP_ORD_PROTOCOL_ANDROID_TAB_MX_OWNS = 'Android Tablet (Merchant Owns)';
    public static final String OPP_ORD_PROTOCOL_EMAIL = 'Email';
    public static final String OPP_ORD_PROTOCOL_FAX = 'Fax';
    public static final String OPP_ORD_PROTOCOL_OTHER= 'Other';
    public static final String OPP_ORD_PROTOCOL_TAB_DD_OWNS = 'Tablet (DoorDash Owns)';
    public static final String OPP_ORD_PROTOCOL_TAB_PRNT_DD_OWNS = 'Tablet and Printer (DoorDash Owns)';
    public static final String OPP_ORD_PROTOCOL_POS = 'POS';
    public static final String OPP_ORD_PROTOCOL_POS_TAB_MX_OWNS = 'POS and Tablet (Merchant Owns)';
    public static final String OPP_ORD_PROTOCOL_POS_TAB_DD_OWNS = 'POS and Tablet (DoorDash Owns)';

    //Account Merchant Category
    public static final String ACC_MERCH_CAT_PREP_FOOD = 'Prepared Food & Drink (Rx)'; 
    public static final String ACC_MERCH_CAT_GOV = 'Government';
    public static final String ACC_MERCH_CAT_NON_PROFIT = 'Non-Profit Incumbents';
}