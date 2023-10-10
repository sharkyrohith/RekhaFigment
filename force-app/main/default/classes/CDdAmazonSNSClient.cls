/**
 * @description       : Simple Amazon SNS Client
 * @author            : Jose Vega
 * @last modified on  : 09-29-2022
 * @last modified by  : Jose Vega
**/
public with sharing class CDdAmazonSNSClient {

    public static Response publish(String message, String messageGroupId, String topicARN) {
        Response sqsResponse = new Response();
        try {
            HttpRequest req = new HttpRequest();
            String resource = '?Action=Publish' +
                '&MessageGroupId=' + EncodingUtil.urlEncode(messageGroupId, 'UTF-8') +
                '&TopicArn=' + topicARN +
                '&Message=' + EncodingUtil.urlEncode(message, 'UTF-8');
            req.setEndpoint('callout:AmazonSNSAPI/' + resource);
            req.setMethod('POST');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            sqsResponse.success = successResponse(res.getBody());
        } catch(Exception e) {
            List<String> errorMessage = new List<String>();
            errorMessage.add(e.getMessage());
            CDdErrorUtilities.createApexLogs(errorMessage, 'CDdAmazonSNSClient');
            sqsResponse.success = false;
            sqsResponse.message = e.getMessage();
        }

        return sqsResponse;
    }

    /**
    * @description Parses String into XML
    * @author Jose Vega | 09-20-2022 
    * @param String response // XML string
    * @return Boolean 
    **/
    private static Boolean successResponse(String response) {
        System.debug(response);
        Boolean successResponse = false;
        try {
            Dom.Document doc = new Dom.Document();
            doc.load(response);
            Dom.XMLNode rootElement = doc.getRootElement();
            for ( Dom.XMLNode childElement : rootElement.getChildElements() ) {  
                for ( Dom.XMLNode detailElement : childElement.getChildElements() ) {
                    // system.debug( detailElement.getName() + '-' + detailElement.getText() );
                    if (detailElement.getName() == 'MessageId') {
                        successResponse = true;
                    }
                }
            }
        }catch(Exception e) {
            successResponse = false;
        }
        return successResponse;
    }

    public class Response{
        public Boolean success;
        public String message;
    }

}