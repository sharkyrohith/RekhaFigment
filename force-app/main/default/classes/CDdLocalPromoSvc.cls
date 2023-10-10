/**
* @author: Ed Kim
* @date: 2019-03-25
* @description Service class for callouts to /v1/consumer_promotions/
PAP Weblink ID:   PAP_Weblink_ID__c
PAP Promotion Code:   PAP_Promotion_Code__c
PAP?: PAP__c
*/
public class CDdLocalPromoSvc {
    // static CDdRESTConnectorSvc restSvc = new CDdRESTConnectorSvc();
    // static final date todayDate = Date.today();

    // public Boolean createLocalPromo(List<Account> accts) {
    //     Opportunity weblinkOpp;
    //     Opportunity consumerPromoOpp;
    //     List<Account> updateAccts = new List<Account>();

    //     for (Account acct : accts) {
    //         if (acct.Restaurant_ID__c == null) continue;

    //         List<Opportunity> localPromoOpps = [SELECT Id, LastModifiedDate, Type
    //                                             FROM Opportunity
    //                                             WHERE AccountId	= :acct.Id 
    //                                             AND RecordType.DeveloperName='Post_Sale'
    //                                             AND StageName = 'Closed Won'
    //                                             AND Type in ('Weblinks', 'In-Store Marketing')];
            
    //         if (localPromoOpps.size() == 0) {
    //             localPromoOpps = [SELECT Id, LastModifiedDate, Type
    //                               FROM Opportunity
    //                               WHERE AccountId = :acct.ParentId 
    //                               AND RecordType.DeveloperName='Post_Sale'
    //                               AND StageName = 'Closed Won'
    //                               AND Type in ('Weblinks', 'In-Store Marketing')];
    //         }

    //         for (Opportunity opp : localPromoOpps) {
    //             if (opp.Type == 'Weblinks') {
    //                 if (weblinkOpp == null || (weblinkOpp != null && weblinkOpp.LastModifiedDate > opp.LastModifiedDate)) {
    //                     weblinkOpp = opp;
    //                 }
    //             }
    //             if (opp.Type == 'In-Store Marketing') {
    //                 if (consumerPromoOpp == null || (consumerPromoOpp != null && consumerPromoOpp.LastModifiedDate > opp.LastModifiedDate)) {
    //                     consumerPromoOpp = opp;
    //                 }
    //             }
    //         }

    //         if (webLinkOpp == null && consumerPromoOpp == null) continue;

    //         try {
    //             CDdRestJSONObj.storeBountyProgramLinkRequest req = new CDdRestJSONObj.storeBountyProgramLinkRequest();
    //             req.store_id = Integer.valueOf(acct.Restaurant_Id__c);
    //             req.SFDC_account_id = acct.Id;
    //             req.bounty_programs = new List<CDdRestJSONObj.BountyProgram>();
    //             if (webLinkOpp != null) {
    //                 CDdRestJSONObj.BountyProgram weblinkBP = new CDdRestJSONObj.BountyProgram();
    //                 weblinkBP.type = 'weblink';
    //                 weblinkBP.amount = 1000;
    //                 weblinkBP.description = '';
    //                 req.bounty_programs.add(weblinkBP);
    //             }
    //             if (consumerPromoOpp != null) {
    //                 CDdRestJSONObj.BountyProgram consumerBP = new CDdRestJSONObj.BountyProgram();
    //                 consumerBP.type = 'consumer_promotion';
    //                 consumerBP.start_date_time = String.valueOf(todayDate);
    //                 // Optional Field
    //                 // weblinkBP.end_date_time = todayDate.addDays(365); 
    //                 consumerBP.amount = 1000;
    //                 consumerBP.description = '';
    //                 req.bounty_programs.add(consumerBP);
    //             }

    //             List<CDdRestJSONObj.BountyProgramResponse> body = createLocalPromoReq(req);
    //             System.debug(body);
    //             for (CDdRestJSONObj.BountyProgramResponse bounty_program : body) {
    //                 if (bounty_program.type == 'weblink') {
    //                     acct.PAP_Weblink_ID__c = bounty_program.id;
    //                     acct.PAP__c = false;
    //                 } else if (bounty_program.type == 'consumer_promotion') {
    //                     acct.PAP_Promotion_Code__c = bounty_program.consumer_promotion.code;
    //                     acct.PAP__c = false;
    //                 }
    //                 if (!updateAccts.contains(acct)) {
    //                     updateAccts.add(acct);
    //                 }
    //             }
    //         } catch (Exception e) {
    //             System.debug(e);
    //             // acct.addError(e);
    //         } finally {
    //             weblinkOpp = null;
    //             consumerPromoOpp = null;
    //         }
    //     }

    //     if (updateAccts.size() > 0) {
    //         Database.update(updateAccts, false);
    //         return true;
    //     }
    //     return false;

    // }

    // public static List<CDdRestJSONObj.BountyProgramResponse> createLocalPromoReq(CDdRestJsonObj.storeBountyProgramLinkRequest req) {
    //     System.debug(JSON.serialize(req, true));
    //     CDdRestJSONObj.RestAPIResponse res = restSvc.postDoorstep(JSON.serialize(req, true), '/v1/store_bounty_program_links');

    //     if (res.statusCode != 200) {
    //         throwCalloutException(String.valueOf(res.statusCode));
    //     }

    //     return (List<CDdRestJSONObj.BountyProgramResponse>) JSON.deserialize(res.body, List<CDdRestJSONObj.BountyProgramResponse>.class);
    // }

    // private static void throwCalloutException(String statusCode) {
    //     CalloutException e = new CalloutException();
    //     e.setMessage('There was an error with the request. Status Code: ' + statusCode);
    //     throw e;
    // }

    // // public static String testjson =		'['+
	// // 	'    {'+
	// // 	'        "type": "weblink",'+
	// // 	'        "id": 10363'+
	// // 	'    },'+
	// // 	'    {'+
	// // 	'        "consumer_promotion": {'+
	// // 	'            "code": "2CWXCH3",'+
	// // 	'            "id": 84785,'+
	// // 	'            "submarkets": ['+
	// // 	'                {'+
	// // 	'                    "id": 2'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 6'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 10'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 33'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 37'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 39'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 83'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 87'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 101'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 992'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 1205'+
	// // 	'                },'+
	// // 	'                {'+
	// // 	'                    "id": 1586'+
	// // 	'                }'+
	// // 	'            ]'+
	// // 	'        },'+
	// // 	'        "type": "consumer_promotion",'+
	// // 	'        "id": 10364'+
	// // 	'    }'+
	// // 	']';

}