/*
*@Description: OCUS Service class to make API service call
@Author : Veera Maddukuri
@Date : 11/23/2021
*/
public with sharing class CDdOCUSAPIService {

    public static CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
    public static Map<String,CDdAPICredentialData.CredentialWrapper> credentialData = CDdAPICredentialData.getCredentialWrapper(CDdAPICredentialData.OCUS_CATEGORY);
    /*
    *@Description: method to make POST Api call to the OCUS 
    */
    public static CDdRestJSONObj.OCUSMissionResponse postOCUSMilestoneAPI(CDdRestJSONObj.OCUSAPIRequest bookingRequest,String namedCredential, String postfixURL){
        CDdRestJSONObj.OCUSMissionResponse missionResponse = new CDdRestJSONObj.OCUSMissionResponse();
        try{
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI('POST', JSON.serialize(bookingRequest,true), null, null, postfixURL, null, namedCredential);
            missionResponse = CDdOCUSAPIServiceHelper.handleMissionResponse(response);
        }catch(Exception ex){
            missionResponse.isSuccess = false;
            missionResponse.message = ex.getMessage();
        }
        return missionResponse;
    }


    /*
    *@Description: method to make GET Api call to the OCUS 
    */ 
    public static CDdRestJSONObj.OCUSMissionResponse getOCUSMilestoneAPI(String namedCredential,String postfix){
        CDdRestJSONObj.OCUSMissionResponse missionResponse = new CDdRestJSONObj.OCUSMissionResponse();
        try{
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI('GET', null, null, null, postfix, null, namedCredential);
            missionResponse = CDdOCUSAPIServiceHelper.handleMissionResponse(response);
            System.debug('OCUS '+missionResponse);
        }catch(Exception ex){
            missionResponse.isSuccess = false;
            missionResponse.message = ex.getMessage();
        }
        return missionResponse;
    }

   /*
    *@Description: method to make PATCH Api call to the OCUS 
    */
    public static CDdRestJSONObj.OCUSMissionResponse updateOCUSMilestoneAPI(CDdRestJSONObj.OCUSAPIRequest bookingRequest,String namedCredential, String postfixURL,String uid){
        CDdRestJSONObj.OCUSMissionResponse missionResponse = new CDdRestJSONObj.OCUSMissionResponse();
        try{
            CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI('PATCH', JSON.serialize(bookingRequest,true), null, null, postfixURL+'/'+uid, null, namedCredential);
            missionResponse = CDdOCUSAPIServiceHelper.handleMissionResponse(response);
        }catch(Exception ex){
            missionResponse.isSuccess = false;
            missionResponse.message = ex.getMessage();
        }
        return missionResponse;
    }
    
}