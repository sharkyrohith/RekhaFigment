/**
  * @author:Narender K
  * @date  07/14/2021
  * @decription: This class is used as helper class to CDdUserNestingCtrl class and CDdBulkAPIUtility class.
  */
public class CDdPresenceConfigQueueable implements Queueable,Database.AllowsCallouts{
    public static final String AUTHORIZATION_LABEL  = 'Authorization';
    public static final String BEARER_LABEL  = 'Bearer ';
    public static final String POST_LABEL  = 'POST';
    public static final Integer SET_TIME_OUT  = 120000;
    public static final String API_DELETE_METHOD  = 'DELETE';
    public static final Integer BATCH_SIZE = 200;
    public static final Integer SUCCESS_CODE = 201;
    public static final String CONTENT_TYPE_LABEL  = 'content-type';
    public static final String APPLICATION_JSON_LABEL  = 'application/json';
    public static final String ALLORNONE_LABEL  = 'allOrNone';
    public static final String FALSE_LABEL  = 'false';
    public static final String DOMAIN_URL_NAME = URl.getOrgDomainUrl().toExternalForm(); 
    public static final String INS_QBL_CLSNAME = 'insertPresenceUserConfigUserQueueable';
    public static final String PRE_QBL_CLSNAME = 'CDdPresenceConfigQueueable';
    public static final String DLT_API_MTHD = 'deletePresenceUserConfigUser';
    public static final Integer START_INDEX_0 = 0;
    public static CDdRESTConnectorSvc connector = new CDdRESTConnectorSvc();
    
    public List<PresenceUserConfigUser> presUserCfgUserList;
    public List<Id> presUserIds = new List<Id>();
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: constructor to assign values to params
    * @param   List of PresenceUserConfigUser, List of Ids
    * @return  None
    */
    public CDdPresenceConfigQueueable(List<PresenceUserConfigUser> presUserConfigUserList,List<Id> systemUserIds){
        presUserCfgUserList = presUserConfigUserList ;
        presUserIds = systemUserIds;
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: execute method of queueable
    * @param   QueueableContext qc
    * @return  None
    */
    public void execute(QueueableContext qc){
        try{
            List<Id> presenceUserConfigIds = new List<Id>();
            for(PresenceUserConfigUser puconf : [
                SELECT Id 
                FROM PresenceUserConfigUser 
                WHERE Userid IN :presUserIds]){
                    presenceUserConfigIds.add(puconf.Id);
                }
            boolean checkDeleteBatch = false;
            
            if(!presenceUserConfigIds.isEmpty() && presenceUserConfigIds.size()<201){
                checkDeleteBatch = true; 
            }
            String presUserConfigId = '';
            for(Integer i = 0; i < presenceUserConfigIds.size(); i++){
                if(String.isBlank(presUserConfigId)){
                    presUserConfigId =  presenceUserConfigIds[i];    
                }
                else{
                    presUserConfigId = presUserConfigId+','+presenceUserConfigIds[i]; 
                }
                if(!checkDeleteBatch && math.mod(i, 199)==0){
                    deletePresenceUserConfigUser(presUserConfigId);
                    presUserConfigId = '';
                }
                else if(!checkDeleteBatch && i== presenceUserConfigIds.size()-1){
                    deletePresenceUserConfigUser(presUserConfigId);
                }
            }
            if(checkDeleteBatch){
                deletePresenceUserConfigUser(presUserConfigId);  
            }
            List<WrapperData> wrplist = new List<WrapperData>();
            for(PresenceUserConfigUser presUserRec : presUserCfgUserList){
                WrapperAttributes atr = new WrapperAttributes();
                atr.type = CDdSupportConstants.PRESENCEUSERCONFIGUSER_OBJECT_LABEL;
                WrapperData wrpdata = new WrapperData();
                wrpdata.Userid = presUserRec.UserId;
                wrpdata.PresenceUserConfigId = presUserRec.PresenceUserConfigId;
                wrpdata.attributes = atr;
                wrplist.add(wrpdata);
            }
            if(!wrplist.isEmpty()){
                CDdPresenceConfigQueueable.insertPresenceUserConfigUserQueueable insertQueueInstance = new CDdPresenceConfigQueueable.insertPresenceUserConfigUserQueueable('CDdPresenceConfigQueueable',wrplist,BATCH_SIZE,START_INDEX_0);
                Id JobId = System.enqueueJob(insertQueueInstance); 
            }
        }
        Catch(Exception ex){
            CDdErrorUtilities.publishException(CDdSupportConstants.PRESENCEUSERCONFIGUSER_OBJECT_LABEL, PRE_QBL_CLSNAME, ex);
        }
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: deletes PresenceUserConfigUser records
    * @param   string of PresenceUserConfigIds
    * @return  sting to indiacte success
    */
    public static string deletePresenceUserConfigUser(String presUserCfgIds){
        if(String.isNotBlank(presUserCfgIds)){
            try{
                CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(API_DELETE_METHOD, null, null, null, 
                        '/services/data/v50.0/composite/sobjects', null, 'ids='+presUserCfgIds+'&'+ALLORNONE_LABEL+'='+FALSE_LABEL, 'SalesforceNamedCred');
                if(response != null && response.statusCode != CDdCoreConstants.CODE_REQUEST_SUCCESS && response.statusCode != SUCCESS_CODE){
                    throw new APIException(response.statusCode +' : '+response.body); 
                }
            }
            Catch(Exception ex){
                system.debug('Error Msg....'+ex.getMessage());
                CDdErrorUtilities.publishException(CDdSupportConstants.PRESENCEUSERCONFIGUSER_OBJECT_LABEL, DLT_API_MTHD, ex);
            }
            
        }
        return 'Success';
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: Inner queueable class to insert PresenceUserConfigUser records
    * 
    */
    public class insertPresenceUserConfigUserQueueable implements Queueable,Database.AllowsCallouts{
        private List<WrapperData> wrpList{get;set;}
        private Integer batchSize {get;set;}
        private Integer startIndex{get;set;}
        private Integer noOfRequests{get;set;}
        private String inContext{get;set;}
        
       /** 
        * @author     Naren K
        * @date  07/14/2021
        * @decription: constructor for recursive calls
        * @param   string of PresenceUserConfigIds
        * @return  none
        */ 
        public insertPresenceUserConfigUserQueueable(String inContext,List<WrapperData> wrpList, Integer batchSize,Integer startIndex){
            this.wrpList = wrpList;
            this.startIndex = startIndex;
            this.noOfRequests = wrpList.size();
            this.batchSize = batchSize;
            this.inContext = inContext;
        }
       /** 
        * @author     Naren K
        * @date  07/14/2021
        * @decription: override the execute method to recursively call until all records are processed
        * @param   System.QueueableContext qc
        * @return  None
        */
        public void execute (System.QueueableContext qc){
            try{ 
                RequestWrapper reqwrp = new RequestWrapper();
                Integer endIndex = this.getEndIndex();
                System.debug(endIndex);
                List<WrapperData> requestsToBeProcessedNext = new List<WrapperData>();
                // extract the records that need to be processed
                for (Integer idx = startIndex; idx <=endIndex; idx++){
                    requestsToBeProcessedNext.add(wrpList.get(idx));
                }
                reqwrp.records = requestsToBeProcessedNext;
                // it is Insert 
                CDdRestJSONObj.RestAPIResponse response = connector.invokeRESTAPI(POST_LABEL, JSON.serialize(reqwrp), null, null, 
                        '/services/data/v51.0/composite/sobjects', APPLICATION_JSON_LABEL, 'SalesforceNamedCred');
                if(response != null && response.statusCode != CDdCoreConstants.CODE_REQUEST_SUCCESS && response.statusCode != SUCCESS_CODE){
                    throw new APIException(response.statusCode +' : '+response.body); 
                }
                // are there requests that need to be processed/left, call the recursive
                if (this.noOfRequests > endIndex + 1){    
                    insertPresenceUserConfigUserQueueable queueableInstance = new insertPresenceUserConfigUserQueueable(this.inContext,this.wrpList,this.batchSize,endIndex+1);
                    Id JobId = System.enqueueJob(queueableInstance);
                    System.debug(JobId);
                }    
            }
            Catch(Exception ex){
                system.debug('Error Msg....'+ex.getMessage());
                CDdErrorUtilities.publishException(CDdSupportConstants.PRESENCEUSERCONFIGUSER_OBJECT_LABEL, INS_QBL_CLSNAME, ex);
            }
        }
        
       /** 
        * @author     Naren K
        * @date  07/14/2021
        * @decription: gets the end index
        * @param   None
        * @return  None
        */
        // get the last index of the batch to be processed, given the start index and batch size
        public Integer getEndIndex(){
            if (this.noOfRequests > this.startIndex + batchSize - 1){
                return this.startIndex + batchSize - 1;
            }
            else{
                return this.noOfRequests - 1;
            }
        }
    }     
    public class APIException extends Exception {
    }
    
    /** 
    * @author     Naren K
    * @date  07/14/2021
    * @decription: wrapper class to hold values
    * 
    */
    public class WrapperData{
        public string Userid;
        public string PresenceUserConfigId;
        public WrapperAttributes attributes;
    }
    public class WrapperAttributes{
        public string type;
    }
    public class RequestWrapper{
        public List<WrapperData> records;
    }
    
}