/**
 * CDdMxSxSegmentConstants
**/
public class CDdMxSxSegmentConstants {
    public static final STRING SETTINGSNAME ;
    public static final Segment_Settings__mdt SEGMENTSETTINGS;
    public static final Integer SEGMENT_MAXIMUM_RETRY_COUNT ;
    public static final Integer SEGMENT_MAXIMUM_RETRY_EVENTS_COUNT ;
    public static final Integer DEFAULT_BATCH_LAST_MODIFIED_DAYS ;
    public static final Integer DEFAULT_BATCH_SIZE ;
    public static final Integer DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS ;
    public static final Integer DEFAULT_BATCH_FOR_ARCHIVAL_SIZE ;
    public static final Integer DEFAULT_MINUTES_FOR_LOG_HANDLER ;
    public static final Integer PREVIOUS_EVENT_CREATED_IN_LAST_N_SECONDS ;

    public static final STRING SUCESS_STATUS = 'Success';
    public static final STRING NOT_REQUIRED_STATUS = 'Not Required';
    public static final Set<STRING> IGNORE_LOG_STATUS = new Set<STRING>{
        SUCESS_STATUS,
        NOT_REQUIRED_STATUS
    };
    public static final STRING SEGMENT_EVENT_REQUEST_COMPLETE = 'Segment Request Constructed';
    public static final STRING SEGMENT_EVENT_PUBLISHED_STATUS = 'Segment Event Published';
    public static final STRING SEGMENT_EVENT_FAILED_STATUS = 'Segment Event Publish Failed';

    public static final String SOBJECT_TYPE_MILESTONE = 'Milestone__c';
    public static final String USER_ID = 'segmentUserID';
    public static final String SEGMENT_TRACK_EVENT = 'track';
    public static final String SEGMENT_BATCH_EVENT = 'batch';



    public static final String STATICPROPERTYTYPE = 'Static';
    public static final String TIMEFORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'' ;
    public static final String TIMESTAMPZONE = 'GMT';

    public static final String UUIDKEY = 'uuid';

    public static final Boolean ENABLE_SEGMENT_FRAMEWORK;
    public static final Boolean PUBLISH_EVENTS_TO_SEGMENT;

    public final static Boolean ISEXECUTIONINBATCHCONTEXT;
    public final static Boolean ISEXECUTIONINTRIGGERCONTEXT;

    public final static String NAMED_CREDENTIAL_NAME ;
    public final static String SEGMENT_CALLOUT_METHOD = 'POST';
    public final static String AUTHORIZATION_HEADER_KEY = 'Authorization';

    //Error Emails
    public final static String NORESPONSEERRORSUBJECT = 'Unable to Process Segment Records through Mulesoft' ;
    public final static String NORESPONSEERRORBODY = 'Hi<br /><br />There were {0} records from the current batch which are directly processed to Segment.<br /><br />Thanks!' ;
    
    public static final Set<String> LOG_STATUS_NOT_TO_DELETE = new Set<String>{
        'Failed'
    };
    
    static {
        SETTINGSNAME = ([SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox)? 'Sandbox':'Production' ;
        SEGMENTSETTINGS = Segment_Settings__mdt.getInstance(SETTINGSNAME) ;
        SEGMENT_MAXIMUM_RETRY_COUNT = Integer.valueOf(SEGMENTSETTINGS.Maximum_Retry_Count__c) ; 
        SEGMENT_MAXIMUM_RETRY_EVENTS_COUNT = Integer.valueOf(SEGMENTSETTINGS.Maximum_Platform_Event_Retry_Count__c) ; 
        DEFAULT_BATCH_LAST_MODIFIED_DAYS = Integer.valueOf(SEGMENTSETTINGS.Log_Records_Last_Modified_In_Days__c) ;
        DEFAULT_BATCH_SIZE = Integer.valueOf(SEGMENTSETTINGS.Log_Handler_Batch_Size__c) ;
        DEFAULT_BATCH_FOR_ARCHIVAL_LAST_MODIFIED_DAYS = Integer.valueOf(SEGMENTSETTINGS.Data_Archival_Not_Modified_In_Days__c) ;
        DEFAULT_BATCH_FOR_ARCHIVAL_SIZE = Integer.valueOf(SEGMENTSETTINGS.Data_Archival_Batch_Size__c) ;
        DEFAULT_MINUTES_FOR_LOG_HANDLER = Integer.valueOf(SEGMENTSETTINGS.Log_Records_Not_Updated_In_Minutes__c) ;
        NAMED_CREDENTIAL_NAME = SEGMENTSETTINGS.Named_Credential__c ;
        PREVIOUS_EVENT_CREATED_IN_LAST_N_SECONDS = Integer.valueOf(SEGMENTSETTINGS.Previous_Event_Created_In_Last_N_Seconds__c);
        if(!String.isBlank(SEGMENTSETTINGS.Status_To_Be_Excluded_from_Archival__c)){
            LOG_STATUS_NOT_TO_DELETE.addALL(SEGMENTSETTINGS.Status_To_Be_Excluded_from_Archival__c.split(','));
        }
        
        ENABLE_SEGMENT_FRAMEWORK = (Test.isRunningTest() || (CDdExperimentSvc.getFeatureFlag('Enable_Segment_Framework__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Enable_Segment_Framework__c')));
        PUBLISH_EVENTS_TO_SEGMENT = ((CDdExperimentSvc.getFeatureFlag('Publish_Events_to_Segment__c') == null ? false : CDdExperimentSvc.getFeatureFlag('Publish_Events_to_Segment__c')));
        ISEXECUTIONINBATCHCONTEXT = System.isBatch();
        ISEXECUTIONINTRIGGERCONTEXT = Trigger.isExecuting ;

    }
    
}