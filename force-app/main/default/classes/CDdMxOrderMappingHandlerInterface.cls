/********************************************************************************************************************
* @author Sriram
* @date 03/16/2022
*
* @group Merchant Services
*
* @description Mapping handler interface
*              Apex Handler Interface for executing specific logic to copy over field values from Source to Target sObject
* 
**************************************************************************************************************************************/
public interface CDdMxOrderMappingHandlerInterface {

    Set<String> getSourceSObjectApiFields();

    Set<String> getTargetSObjectApiFields();

    Boolean copyFields(CDdMxOrderEventEnum event, SObject sourceSObject, SObject targetSObject, String targetSObjectDmlOperation);
}