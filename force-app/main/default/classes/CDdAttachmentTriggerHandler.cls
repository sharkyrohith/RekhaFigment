/**
* @author Tia Xuan
* @date 2022-03
*
* @description Test class for CDdACContactTraceTriggerHandler
*/
public class CDdAttachmentTriggerHandler {

    public static final String FORMSTACK_INTEGRATION_USER_ID = '0051a000002UzQ0AAK';
    public static final String DOWNLOAD_LINK_PORTION = '&export=download';
    public static final String EMPTY_STRING = '';
    public static final String GOOGLE_DRIVE_URL = 'https://drive.google.com';
    public static final String NAME_SEPERATOR = ' - ';

    public void beforeInsert(List<Attachment> newList) {
        treatFormstackPhotoAttachment(newList);
    }

    // BASD-24383
    // https://doordash.atlassian.net/browse/BASD-24383

    public void treatFormstackPhotoAttachment(List<Attachment> newList){
        List<Id> caseIdList = new List<Id>();
        for (Attachment attach: newList){
            if ( attach != null
                && attach.OwnerId != null
                && String.isNotBlank(attach.name)
                && (attach.OwnerId == FORMSTACK_INTEGRATION_USER_ID || Test.isRunningTest())
                && attach.Name.startsWith(GOOGLE_DRIVE_URL)){
                caseIdList.add(attach.ParentId);
            }
        }

        Map<Id, Case> caseList = new Map<Id, Case>([select Id, CaseNumber, Origin, Account.Name, AccountId
                                                    from Case
                                                    where Id =: caseIdList]);

        for (Attachment attach: newList){
            if (attach.OwnerId == FORMSTACK_INTEGRATION_USER_ID || Test.isRunningTest()){
                if (String.isNotBlank(attach.Name)){
                    if (attach.Name.contains(DOWNLOAD_LINK_PORTION)){
                        attach.Name = attach.Name.replaceAll(DOWNLOAD_LINK_PORTION, EMPTY_STRING);
                    }
                    if (attach.Name.startsWith(GOOGLE_DRIVE_URL)){
                        attach.Description = attach.Name;
                        if (caseList.containsKey(attach.ParentId)){
                            case parentCase = caseList.get(attach.ParentId);
                            List<String> nameParts = new List<String>();
                            nameParts.add(parentCase.CaseNumber);
                            if (parentCase.AccountId != null){
                                nameParts.add(parentCase.Account.Name);
                            }
                            if (String.isNotBlank(parentCase.Origin)){
                                nameParts.add(parentCase.Origin);
                            }
                            attach.Name = String.join(nameParts , NAME_SEPERATOR);
                        }
                    }
                }
            }
        }

    }

}