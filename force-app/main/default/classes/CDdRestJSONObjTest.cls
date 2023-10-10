@IsTest
public class CDdRestJSONObjTest {
    @IsTest
    public static void testCDdRestJSONObj() {
        CDdRestJSONObj.parseStoreResponse('{}');

        CDdRestJSONObj.StripeBankTokenRequest stripeBankTokenRequest = new CDdRestJSONObj.StripeBankTokenRequest();
        stripeBankTokenRequest.getURLEncoded();

        CDdRestJSONObj.StripeAccountTokenRequest stripeAccountTokenRequest = new CDdRestJSONObj.StripeAccountTokenRequest();
        stripeAccountTokenRequest.getURLEncoded();

        CDdRestJSONObj.StripePersonTokenRequest stripePersonTokenRequest = new CDdRestJSONObj.StripePersonTokenRequest();
        stripePersonTokenRequest.getURLEncoded();

        CDdRestJSONObj.StripeError stripeError = new CDdRestJSONObj.StripeError();
        stripeError.getFormattedError();

        CDdRestJSONObj.StripeExternalAccountRequest stripeExternalAccountRequest = new CDdRestJSONObj.StripeExternalAccountRequest();
        stripeExternalAccountRequest.getURLEncoded();
   }
}