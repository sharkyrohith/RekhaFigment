/********************************************************************************************************************
 * @author Praveen
 * @date 09/17/2022
 *
 * @group Merchant Services
 *
 * @description helper class determine the case type bases on the origin.
 * 
 *
 **************************************************************************************************************************************/

public class CDdMxSxCaseOriginHandler {
    /**
     * @description Method to decide whether given is created using Equipment request UI screen for tablets.
     * @param String
     * @return Boolean
     */
    public static Boolean isEquipmentRequestSupportCase(String caseOrigin){
        return String.isNotBlank(caseOrigin) && caseOrigin.left(2).equals('UI')?true:false;
    }
}