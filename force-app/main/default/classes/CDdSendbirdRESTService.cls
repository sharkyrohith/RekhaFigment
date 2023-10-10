/**
 * CDdSendbirdRESTService
 *
 * @author     Sahil (sahil.chaudhry@doordash.com)
 * @date       2022-07-12
 * @decription REST webservice for Sendbird Chat features
*/
@RestResource(urlMapping='/chatservice/*')
global with sharing class CDdSendbirdRESTService {
    /*****************************************************************************************************************************
    *
    * Public Methods
    *
    *****************************************************************************************************************************/
     /**
     * @author      Sahil Chaudhry
     * @date        07/2022
     * @decription  handle GET calls made by the client
     * @param       none
     * @return      serialized JSON response
    */
    @HttpGet
    global static ResponseWrapper doGet() {
        try {
            RestRequest req = RestContext.request;
            String actionParam = req.params.get('action');
            if (String.isBlank(actionParam)) {
                throw new CDdSendbirdRESTServiceException('action parameter not defined');
            }
            ResponseWrapper respWrapperObj = new ResponseWrapper();
            switch on actionParam {
                when 'transfer_queues','quick_text' {
                    Map<String,Object> responseMap = (Map<String,Object>) CDdSendbirdChatController.processSendbirdAction(actionParam, null);
                    if (!responseMap.isEmpty()) {
                        respWrapperObj.items = JSON.serialize(responseMap.get('items'));
                    }
                    return respWrapperObj;
                }
            }
            throw new CDdSendbirdRESTServiceException('invalid action: '+actionParam);
        } catch (Exception e) {
            throw new CDdSendbirdRESTServiceException(e.getMessage());
        }
    }

    /**
     * @author      Sahil Chaudhry
     * @date        07/2022
     * @decription  handle PATCH calls made by the client
     * @param       none
     * @return      Object
    */
    @HttpPatch
    global static ResponseWrapper handlePatch() {
        try {
            RestRequest req = RestContext.request;
            String actionParam = req.params.get('action');
            if (String.isBlank(actionParam)) {
                throw new CDdSendbirdRESTServiceException('action parameter not defined');
            }
            ResponseWrapper respWrapperObj = new ResponseWrapper();
            switch on actionParam {
                when 'transfer_chat' {
                    String caseId = req.params.get('caseId');
                    String newOwnerId = req.params.get('newOwnerId');
                    if (String.isBlank(caseId)) {
                        throw new CDdSendbirdRESTServiceException('case Id is required');
                    }
                    if (String.isBlank(newOwnerId)) {
                        throw new CDdSendbirdRESTServiceException('new Owner Id is required');
                    }
                    Map<String,String> transferCaseMap = new Map<String,String> {
                                                            'caseId' => caseId,
                                                            'newOwnerId' => newOwnerId };
                    respWrapperObj.items =
                        JSON.serialize(CDdSendbirdChatController.processSendbirdAction(actionParam, transferCaseMap));
                }
            }
            return respWrapperObj;
        } catch (Exception e) {
            throw new CDdSendbirdRESTServiceException(e.getMessage());
        }
    }

     /**
     * @author      Sahil Chaudhry
     * @date        11/2022
     * @decription  handle POST calls made by the client
     * @param
     * @return
    */
    @HttpPost
    global static ResponseWrapper doPost() {
        try {
            RestRequest req = RestContext.request;
            String actionParam = req.params.get('action');
            if (String.isBlank(actionParam)) {
                throw new CDdSendbirdRESTServiceException('action parameter not defined');
            }
            ResponseWrapper respWrapperObj = new ResponseWrapper();
            switch on actionParam {
                when 'create_case' {
                    respWrapperObj.items = JSON.serialize(CDdSendbirdRESTServiceHelper.createSendbirdChatCase(req.requestBody));
                }
            }
            return respWrapperObj;
        } catch (Exception e) {
            throw new CDdSendbirdRESTServiceException(e.getMessage());
        }
    }

    global class ResponseWrapper {
        global String items {get;set;}
    }

    public class CDdSendbirdRESTServiceException extends Exception{}
}