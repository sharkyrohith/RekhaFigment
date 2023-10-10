/*
*@Description: Class to keep all the validation messages and list values
@Author : Venkat D
@Date : 2022-06
*/
public class CDdSSMOQuoteConstants {
	
    public static final String QUOTE_NOT_APPROVED = 'Quote must be Approved';
    public static final String PRODUCT_SSMO_ELIGIBLE = 'All products should be SSMO eligible';
    public static final String QUOTE_ALREADY_SENT_TO_SSMO = 'A Quote has been sent to SSMO';
    public static final String QUOTE_SENT_TO_SSMO = 'Quote sent to SSMO successfully';
    public static final String PACTSAFE_CONTR_OTHER_QUOTE = 'Multiple quotes on this opportunity currently have Contract Type set to Rep-Enabled SSMO. Please adjust so only one quote has a Rep-Enabled SSMO contract type';
    public static final String PACTSAFE_CONTR_QUOTE = 'PactSafe Contract Type should be set to one of Rep Enabled SSMO values';
    public static final String QUOTE_RELATED_PACTSAFE_RECORD = 'Quote has related PactSafe Request records';
    public static final String OPPORTUNITY_LOCATION = 'Opportunity is not in single location';
    public static final String PRIMARY_QUOTE = 'Quote must be primary';
    public static final String DECK_RANK_MSG = 'If Deck Rank is Ace/King OR your quote contains Caviar, please populate Proposed Date of Activation prior to sending to SSMO';
    public static final String EXPERIENCE_CAVIAR_MSG = 'Caviar Only deals are not eligible for Rep Enabled SSMO';
    public static final String BILLING_COUNTRY;
    public static final String POS_SYSTEM;
    public static final String ORDER_PROTOCOL_MSG;

    public static final List<String> REP_ENABLED_SSMO_LIST;
    public static final List<String> BILLING_COUNTRIES;
    public static final List<String> POS_SYSTEMS;
    public static final List<String> ORDER_PROTOCOLS;

    static{
        REP_ENABLED_SSMO_LIST = new List<String>{'English Rep Enabled SSMO Sign Up Sheet','Spanish Rep Enabled SSMO Sign Up Sheet','French Rep Enabled SSMO Sign Up Sheet','AUS Rep Enabled SSMO Sign Up Sheet'};

        POS_SYSTEMS = new List<String>{'Toast','Square'};
        POS_SYSTEM = 'POS System can only be NULL or ' + String.join(POS_SYSTEMS,' or ');

        BILLING_COUNTRIES = new List<String>{'United States','Canada','Australia'};
        BILLING_COUNTRY = 'Quote not eligible. Country should be '+String.join(BILLING_COUNTRIES, ' or ');

        ORDER_PROTOCOLS = new List<String>{'Tablet and Printer (DoorDash Owns)','Tablet (DoorDash Owns)','Email','Fax','Phone','POS'};
        ORDER_PROTOCOL_MSG = 'Order Protocol should be '+String.join(ORDER_PROTOCOLS, ' or ');
    }
}