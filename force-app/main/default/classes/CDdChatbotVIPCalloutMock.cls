/**
* @author Tia Xuan	
* @date 2021-03
*
* @description Used CDdChatBotVIPCallout
*/
@isTest
global class CDdChatbotVIPCalloutMock implements HttpCalloutMock {
    /**
	* @description default response for VIP Check
	*/
    global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('GET', req.getMethod());
        
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"audience":{"consumer_audience":{"country":"US","cx_unavail_last_3_orders_flag":94,"email":"marioncajucom@yahoo.com","experience":"DOORDASH","first_name":"Marion","id":"31500741","is_vip":false,"last_name":"Crisostomo","phone_number":"+14802745691","vip_tier":0},"dasher_audience":null},"customer_type":"CONSUMER","delivery":{"customer_full_name":"Marion Crisostomo","dasher_full_name":"","delivery_uuid":"975b646b-b6e2-4ea2-92b3-6120bf7159cc","merchant_name":"Jollibee (Chandler -1161210)","order_source":"mp","total_cost":7700}}');
        res.setStatusCode(200);
        return res;
    }


}