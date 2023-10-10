/**
 * @description       : 
 * @author            : Jose Vega
 * @group             : 
 * @last modified on  : 07-20-2022
 * @last modified by  : Jose Vega
**/
//Code Sample: http://sforce.co/1op4X62
global class VEmailPublisherDefaultHandler implements QuickAction.QuickActionDefaultsHandler 
{
    // Empty constructor
    global VEmailPublisherDefaultHandler() {}
    
    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) 
    {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        
        // Check if the quick action is the standard Case Feed send email action
        for(Integer j = 0; j < defaults.size(); j++) 
        {
            if(defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults 
               && defaults.get(j).getTargetSObject().getSObjectType() == EmailMessage.sObjectType  
               && defaults.get(j).getActionName() != 'Case.Send_Email_Lightning'){

                // keeping these here if there is an issue after deployment
                //&& defaults.get(j).getActionName().equals('Case.Email') 
                //&& defaults.get(j).getActionType().equals('Email')) {
                
                sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defaults.get(j);
                break;
            }
        }
        
        if (sendEmailDefaults != null) 
        {
            Case c = [  select Country__c, RecordTypeId FROM Case
                        WHERE Id=:sendEmailDefaults.getContextId()];
                        
            Id caviarRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Caviar_Support');
            Id caviarOnboardingRTId = CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Caviar_Onboarding');
            Id supportRecordTypeId =  CDdGenericTriggerOptimizationHelper.getCaseRecordTypeIdByDevName('Customer');
            
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();
            if (c.RecordTypeId != caviarRTId
                || c.RecordTypeId != caviarOnboardingRTId){
                emailMessage.FromAddress = 'support@doordash.com';
            }

            if(c.RecordTypeId == supportRecordTypeId){
                if(c.Country__c == 'Germany'){
                    emailMessage.ValidatedFromAddress = 'support-de@doordash.com';
                } else if(c.Country__c == 'Japan'){
                    emailMessage.ValidatedFromAddress = 'support-jp@doordash.com';
                }
            }
        }
    }
}