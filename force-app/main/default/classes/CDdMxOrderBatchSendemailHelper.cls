/**
* @author: Swetha Chandu
* @date: 2022-08-01
* @description Once the order has return label(attachment) email the return label to the Merchant helper class.
*/ 
public class CDdMxOrderBatchSendemailHelper{
    public static final String ORDER_DESCRIPTION = 'Return label email sent';
    public void sendingEmail(List<Mx_Order__c> orderList){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Mx_Order__c> updateOrderList = new List<Mx_Order__c>();
        Map<id, Messaging.EmailFileAttachment> OrderIdByAttachment = new Map<id, Messaging.EmailFileAttachment>();
        List<String> aidList = new List<String>();
        EmailTemplate emailTemplate = [select Id, Body from EmailTemplate where Name = :System.label.Email_Template];
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address =:System.label.Support_EmailId];
        for(Mx_Order__c od : orderList) {
            for(Attachment a: od.attachments){
                aidList.add(a.Id);
            }
        }
        for(Attachment file : [Select id, name, body, ContentType from Attachment where Id in :aIdList]){
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(file.Name);
            efa.setBody(file.Body);
            efa.setContentType(file.ContentType);
            OrderIdByAttachment.put(file.id, efa);
        }
                
        for(Mx_Order__c od : orderList) {
            List<Id> attachmentId = new List<Id>();
            if(od.attachments.size()>0 && (String.isBlank(od.Order_Status_Description__c) || !od.Order_Status_Description__c.equalsIgnoreCase(ORDER_DESCRIPTION))){            
                for(Attachment a: od.attachments){
                    attachmentId.add(a.Id);
                }
                if(!OrderIdByAttachment.isempty() && !attachmentId.isempty() && OrderIdByAttachment.containsKey(attachmentId[0])){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] {od.Case__r.Contactemail});
                email.setCcAddresses(new String[] {od.Case__r.Case_Owner_Email__c,od.Account__r.Owner.Email});
                email.setReplyTo(System.label.Support_EmailId);
                if ( owea.size() > 0 ) {
                    email.setOrgWideEmailAddressId(owea.get(0).Id);
                }
                email.setSaveAsActivity(false);
                email.setTargetObjectId(od.Account__r.OwnerId);
                email.setTemplateId(emailTemplate.Id);
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(od.Id);
                email.setFileAttachments(new List<Messaging.EmailFileAttachment>{OrderIdByAttachment.get(attachmentId[0])});
                emails.add(email);
                od.Order_Status_Description__c  = ORDER_DESCRIPTION;                
                od.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_RETURN_LABEL_SENT;
                }
            }
        }
        if(!emails.isEmpty()){
            try{
                Boolean runningInASandbox =CDdMxSxConstants.isSandBox();
                Boolean turnOffEmail = test.isRunningTest() && runningInASandbox;
                if (!turnOffEmail){
                    Messaging.sendEmail(emails);
                }
                if(orderList.size()>0){
                    update orderList;
                }
            }
            catch(Exception e){
                updateOrderList.clear();
                for(Mx_Order__c od : orderList){
                    od.Order_Status__c = CDdMxSxConstants.MX_ORDER_STATUS_LABELED;
                    od.Order_Status_Description__c = e.getMessage();
                    updateOrderList.add(od);
                }
                update updateOrderList;
            }
        }
    }
}