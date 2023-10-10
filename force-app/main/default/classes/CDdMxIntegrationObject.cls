/********************************************************************************************************************
* @author Praveen
* @date 1/17/2023
*
* @group Merchant Services
*
* @description This class is wrapper for pos integration object- Integration_Request__x
**************************************************************************************************************************************/

public class CDdMxIntegrationObject {
	public List<Integration_Request__x> IntegrationRequests;
    public CDdMxIntegrationObject(List<Integration_Request__x> records){
        this.IntegrationRequests = records;
    }
}