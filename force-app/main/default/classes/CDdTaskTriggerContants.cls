/**
 * @description       : 
 * @author            : Dinesh Annapareddy
 * @group             : 
 * @last modified on  : 12-28-2021
 * @last modified by  : Dinesh Annapareddy
**/
public class CDdTaskTriggerContants {
    public Static final String  PRE_SALE_TASK = 'Pre-Sale Type - Update Lead Status';
    public Static final Integer DUE_DATE_THRESHOLD= 2;
    public Static final String  LATEST_Q_ACTIVITY = 'Lastest Qualified Activity';
    //public Map<String, String> recordTypeMap = new Map<String, String>();
    public Static List<String> trustSafetyTeam = new List<String>{
                    'Trust and Safety',
                    'Merchant Services',
                    'Merchant Services (Caviar)','Merchant Services (Weblinks)'};
    public Static List<String> trustSafetyRecordType = new List<String>{'Voicemail'};

    public Static Set<String> dateTimeFieldsOnLead = new Set<String> {'Last_Meeting_Set__c','Last_Meeting_Ran__c'};

    public Static Map<String,List<String>> taskStatusMap = new Map<String,List<String>>{
                    'Trying to Reach' => new List<String>{'Influencer - Got Callback Time'},
                    'DM Found' => new List<String>{'Gate Keeper - Got DM info','Influencer - Got DM info','Decision Maker - Left VM','Decision Maker - Got callback time'},
                    'Meeting Set' => new List<String>{'Decision Maker - Appointment set'},
                    'Meeting Ran / Negotiated' => new List<String>{'Decision Maker - Contract out','Decision Maker - Pitch','Decision Maker - Follow up','Decision Maker - Follow up (Left VM)'},
                    //'Duplicate' => new List<String>{'Duplicate'},
                    //'Not Interested - Cool Down' => new List<String>{'Decision Maker - Not interested'},
                    //'Temporarily Closed' => new List<String>{'No Contact - Business Temporarily Closed'},
                    'Unqualified + Active Partner' => new List<String>{'Unqualified Inbound - Already CW'},
                    'Unqualified + Duplicate' => new List<String>{'Duplicate'},
                    'Unqualified + Consumer /Dasher Enquiry' => new List<String>{'Bad Data / Dasher', 'Support', 'Unqualified Inbound - Dx','Unqualified Inbound - Cx'},
                    'Unqualified + Dead - Location out of Business' => new List<String>{'No Contact - Business Closed'},
                    'Trying to Reach + Unable to speak with influencer or DM' => new List<String>{'No Contact - Left VM', 'No Contact - No Answer'},/**Label-Unable to speak with anyone , API- Unable to speak with influencer or DM */
                    'Trying to Reach + Social Media' => new List<String>{'Social Media'},
                    'Trying to Reach + GK unable to get DM on phone' => new List<String>{'Gate Keeper - Left message','Gate Keeper - Not interested','Influencer - Pitch','Influencer - Got DM info','Influencer - Not interested'}, /**Label-GK Unable/Unwilling Get DM , API- GK unable to get DM on phone */
                    'Trying to Reach + Text Outreach' => new List<String>{'Text Outreach'}
                    };
    public Static Map<String,List<String>> leadStatusMap = new Map<String,List<String>>{
                        'Trying to Reach' => new List<String>{'Not Interested - Cool Down','Temporarily Closed','DM Found','Meeting Set','Meeting Ran / Negotiated'},
                        'DM Found' => new List<String>{'Not Interested - Cool Down'},
                        'Meeting Set' => new List<String>{'Not Interested - Cool Down'},
                        'Meeting Ran / Negotiated' => new List<String>{'Not Interested - Cool Down'},
                        //'Duplicate' => new List<String>{'NO Check'},
                        //'Not Interested - Cool Down' => new List<String>{'Not Interested - Cool Down','Temporarily Closed'},
                        //'Temporarily Closed' => new List<String>{'Not Interested - Cool Down','Temporarily Closed'},
                        'Unqualified + Active Partner' => new List<String>{'NO Check'},
                        'Unqualified + Duplicate' => new List<String>{'NO Check'},
                        'Unqualified + Consumer /Dasher Enquiry' => new List<String>{'NO Check'},
                        'Unqualified + Dead - Location out of Business' => new List<String>{'NO Check'},
                        'Trying to Reach + Unable to speak with influencer or DM' => new List<String>{'NO Check'},
                        'Trying to Reach + Social Media' => new List<String>{'NO Check'},
                        'Trying to Reach + GK unable to get DM on phone' => new List<String>{'NO Check'},
                        'Trying to Reach + Text Outreach' => new List<String>{'NO Check'}
                        };
    public Static Map<String,Map<String,String>> setleadChangeMap()
    {
        DateTime dtime = datetime.now();
        Map<String,Map<String,String>> returnMap= new Map<String,Map<String,String>>{
            'Trying to Reach'=> new Map<String,String>{'Lead_Sub_Status__c' =>NULL,'Status' =>'Trying to Reach'},
            'DM Found'=> new Map<String,String>{'Lead_Sub_Status__c' =>NULL,'Status' =>'DM Found'},
            'Meeting Set'=> new Map<String,String>{'Last_Meeting_Set__c' =>string.valueof(dtime),'Status' =>'Meeting Set'},
            'Meeting Ran / Negotiated'=> new Map<String,String>{'Last_Meeting_Ran__c' =>string.valueof(dtime), 'Status' =>'Meeting Ran / Negotiated'},
            //'Duplicate'=> new Map<String,String>{'Status' =>'Duplicate'},
            //'Not Interested - Cool Down'=> new Map<String,String>{'Lead_Sub_Status__c' =>'Not convinced of incrementality','Status' =>'Not Interested - Cool Down'},
            //'Temporarily Closed'=> new Map<String,String>{'Lead_Sub_Status__c' =>'Unknown','Status' =>'Temporarily Closed'},
            'Unqualified + Active Partner' => new Map<String,String>{'Lead_Sub_Status__c' =>'Active Partner','Status' =>'Unqualified'},
            'Unqualified + Duplicate' => new Map<String,String>{'Lead_Sub_Status__c' => 'Duplicate','Status' =>'Unqualified'},
            'Unqualified + Consumer /Dasher Enquiry' => new Map<String,String>{'Lead_Sub_Status__c' => 'Consumer /Dasher Enquiry','Status' =>'Unqualified'},
            'Unqualified + Dead - Location out of Business' => new Map<String,String>{'Lead_Sub_Status__c' => 'Dead - Location out of Business','Status' =>'Unqualified'},
            'Trying to Reach + Unable to speak with influencer or DM' => new Map<String,String>{'Lead_Sub_Status__c' => 'Unable to speak with influencer or DM','Status' =>'Trying to Reach'},
            'Trying to Reach + Social Media' => new Map<String,String>{'Lead_Sub_Status__c' => 'Social Media','Status' =>'Trying to Reach'},
            'Trying to Reach + GK unable to get DM on phone' => new Map<String,String>{'Lead_Sub_Status__c' => 'GK unable to get DM on phone','Status' =>'Trying to Reach'},
            'Trying to Reach + Text Outreach' => new Map<String,String>{'Lead_Sub_Status__c' => 'Text Outreach','Status' =>'Trying to Reach'}
        };
        return returnMap;
    }


    public Static Set<String> latestQActivity = new Set<String>{'Hubspot Marketing Email Sent','Hubspot Marketing Email Opened','Hubspot Marketing Email Clicked','Hubspot Sales Email Sent'};

    public Static Set<String> getAllLeadStatusValues(){
        List<List<String>> leadStatusMapVals = leadStatusMap.values();
        Set<String> returnValues = new Set<String>();
        for(List<String> lst:leadStatusMapVals)
        {
            returnValues.addAll(lst);
        }

        return returnValues;
    }
    public Static Set<String> getAllTaskStatusValues(){
        List<List<String>> taskStatusMapVals = taskStatusMap.values();
        Set<String> returnValues = new Set<String>();
        for(List<String> lst:taskStatusMapVals)
        {
            returnValues.addAll(lst);
        }

        return returnValues;
    }

    public Static Map<String,String> getRecordTypeMap(String sObjectName)
    {
        Map<String, String> recordType= new Map<String,String>();
        for(RecordType rType: [Select Id,DeveloperName,Name from RecordType where sObjectType =:sObjectName ])
        {
            recordType.put(rType.Id,rType.Name);
        }

        return recordType;
    }
}