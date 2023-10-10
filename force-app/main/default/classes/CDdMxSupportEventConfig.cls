/********************************************************************************************************************
* @author Veera
* @date 04/26/2022
*
* @group Merchant Services
*
* @description to handle database operations for Mx Support Event Configuration Custom Object
* 
**************************************************************************************************************************************/
public class CDdMxSupportEventConfig {

   /** Static variable to store all the Mx_Support_Event_Config__c data  */
    private static Map<CDdMxSupportEventEnum,Mx_Support_Event_Config__c> EVENT_CONFIG_MAP;

    /** Static block to initiate EVENT_CONFIG_MAP */
    static {
        EVENT_CONFIG_MAP = new Map<CDdMxSupportEventEnum, Mx_Support_Event_Config__c>();
        List<Mx_Support_Event_Config__c> eventConfigList = getMxSupportEventList();
        Set<String> allMxSupportEnumNames = getMxSupportEnumNames();

        for(Mx_Support_Event_Config__c eventConfig : eventConfigList){
            if(allMxSupportEnumNames.contains(eventConfig.Event_Name__c) 
            ){
                EVENT_CONFIG_MAP.put(CDdMxSupportEventEnum.valueOf(eventConfig.Event_Name__c), eventConfig);
            }
        }
    }

     /** method returns apex class instance of CDdMxSupportEventInterface */
    public static CDdMxSupportEventInterface getMxSupportInstance(CDdMxSupportEventEnum eventEnum){ 
        return (CDdMxSupportEventInterface)Type.forName(getConfigRecord(eventEnum)?.Apex_Class__c)?.newInstance();
    }

    /**
     * @description Return the batch size configured for the Batch Event
     * @param CDdMxSupportEventEnum
     * @return Integer 
     */   
    public static Integer getBatchSize(CDdMxSupportEventEnum eventEnum){ 
        return Integer.valueOf(getConfigRecord(eventEnum).Batch_Size__c != null ? getConfigRecord(eventEnum).Batch_Size__c : CDdMxSxConstants.DEFAULT_BATCH_SIZE); 
    }

    /**
     * @description Return the LAST_N_DAYS configured for the Batch Event
     * @param CDdMxSupportEventEnum
     * @return Integer 
     */   
    public static Integer getQueryLastNDays(CDdMxSupportEventEnum eventEnum){ 
        return Integer.valueOf(getConfigRecord(eventEnum).Query_Last_N_Days__c != null ? getConfigRecord(eventEnum).Query_Last_N_Days__c : CDdMxSxConstants.DEFAULT_BATCH_LAST_MODIFIED_DAYS);
    }

    /**
     * @description Return the SObject Type configured for the Batch Event
     * @param CDdMxSupportEventEnum
     * @return String 
     */   
    public static String getQuerySObjectType(CDdMxSupportEventEnum eventEnum){ 
        return getConfigRecord(eventEnum).Query_SObject_Type__c;
    }

    /**
     * @description Return the SObject Type configured for the Batch Event
     * @param CDdMxSupportEventEnum
     * @return String 
     */   
    public static Integer getQueryLimit(CDdMxSupportEventEnum eventEnum){ 
        return Integer.valueOf(getConfigRecord(eventEnum).Query_Limit__c != null ? getConfigRecord(eventEnum).Query_Limit__c : CDdMxSxConstants.DEFAULT_QUERY_LIMIT);
    }

    /**
     * @description Return the first CDdMxSupportEventEnum in the config records
     * @param 
     * @return CDdMxSupportEventEnum 
     */  
    public static CDdMxSupportEventEnum getFirstMxSupportEvent(){ 
        List<CDdMxSupportEventEnum> enumList = getMxSupportEvents();
        return enumList.isEmpty() ? null :  enumList.get(0);
    }

    /**
     * @description Return true if there are more records in the config data
     * @param CDdMxSupportEventEnum
     * @return Boolean 
     */  
    public static Boolean hasNextMxSupportEvent(CDdMxSupportEventEnum eventEnum){ 
        List<CDdMxSupportEventEnum> enumList = getMxSupportEvents();
        return enumList.size() > enumList.indexOf(eventEnum)+1;
    }

    /**
     * @description Return the next event in the config data
     * @param CDdMxSupportEventEnum
     * @return CDdMxSupportEventEnum 
    */ 
    public static CDdMxSupportEventEnum getNextMxSupportEvent(CDdMxSupportEventEnum eventEnum){ 
        List<CDdMxSupportEventEnum> enumList = getMxSupportEvents();
        return enumList.get(enumList.indexOf(eventEnum)+1);
    }

    /**
     * @description Return true if sent email checked and emails addresses provided in config records
     * @param CDdMxSupportEventEnum
     * @return Boolean 
    */ 
    public static Boolean isNotififyUsers(CDdMxSupportEventEnum eventEnum){ 
        return getConfigRecord(eventEnum).Send_Email__c && String.isNotBlank(getConfigRecord(eventEnum).Email_Addresses_To_Notify__c);
    }

    /**
     * @description Return list of emails sperated by comma
     * @param CDdMxSupportEventEnum
     * @return List<String> 
    */ 
    public static List<String> emailAddressesToNotify(CDdMxSupportEventEnum eventEnum){ 
        return getConfigRecord(eventEnum).Email_Addresses_To_Notify__c?.split(',');
    }


    /********************************** Helper Methods ***********************************/

    private static List<Mx_Support_Event_Config__c> getMxSupportEventList(){
        return [SELECT Id, Apex_Class__c, Batch_Size__c, Event_Name__c, Query_Last_N_Days__c, Query_SObject_Type__c, Query_Limit__c, Sequence__c, Send_Email__c, Email_Addresses_To_Notify__c 
        FROM Mx_Support_Event_Config__c 
        WHERE Is_Active__c = true ORDER BY Sequence__c ASC];
    }

    private static Set<String> getMxSupportEnumNames(){
        Set<String> enumNames = new Set<String>();
        for (CDdMxSupportEventEnum supportEnum : CDdMxSupportEventEnum.values()){
            enumNames.add(supportEnum.name()); 
        }
        return enumNames;
    }

    @TestVisible
    private static Mx_Support_Event_Config__c getConfigRecord(CDdMxSupportEventEnum eventEnum){ 
        return EVENT_CONFIG_MAP.get(eventEnum);
    }

    public static List<CDdMxSupportEventEnum> getMxSupportEvents(){
        return new List<CDdMxSupportEventEnum>(EVENT_CONFIG_MAP.keySet());
    }
    
}