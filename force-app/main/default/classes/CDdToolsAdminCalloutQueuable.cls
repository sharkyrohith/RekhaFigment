/**
 * @author Nayana
 * @date 12/2022
 * @description Queueable class to make API callouts to Tools Admin API's
 *
**/
public class CDdToolsAdminCalloutQueuable implements Queueable,Database.AllowsCallouts{

    public String actionName;
    public String path;
    public String method;
    public Boolean updateCase;
    public String fieldsToUpdateOnCase;
    public List<Object> lstWrapperToProcess;

    //Constructor of CDdToolsAdminCalloutQueuable
    public CDdToolsAdminCalloutQueuable(String callingFrom, List<Object> lstObjects){
        this.actionName = callingFrom;
        this.lstWrapperToProcess = lstObjects;
    }

    public void execute(QueueableContext context) {
        try{
            Tools_Admin_API__mdt actionApiDetails = [Select Id,Child_Class_name__c, DeveloperName, Label, Path__c, Method__c,(Select Id, Response_Status_Code__c, Response_Message_key__c, Fields_To_Update__c, Email_Template_Name__c, MasterLabel from Tools_Admin_API_actions__r)  from Tools_Admin_API__mdt where DeveloperName = :actionName];
            CDdToolsAdminCallout toolAdminCallout = (CDdToolsAdminCallout)Type.forName(actionApiDetails.Child_Class_name__c).newInstance();
            toolAdminCallout.makeCall(actionApiDetails,lstWrapperToProcess);

        }catch(Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdToolsAdminCallout');
        }
    }
}