/**
 * 
 * @author: Tia Xuan
 * @date: 2019-08
 * @description class for Support channels lightning component LDdContactSupportChannels
 * 
 */
public class CDdContactSupportChannelsController {

    /**
    * @description get wait times for display
    */
    @AuraEnabled
    public static string getWaitTimes(String lang, String comm){
        Decimal five9WT = getFive9WaitTime(lang, comm);
        Decimal liveAgentWT = getChatWaitTime(lang, comm);

        return '{"Five9WaitTime":' + five9WT + ', "LiveAgentWaitTime":' + liveAgentWT + '}';
        
    }

    /**
    * @description Make a call to get Five9 Statistics from service stats sObject
    */
    public static Decimal getFive9WaitTime(String lang, String comm){
        Id five9RecordTypeId = Schema.SObjectType.Service_Statistics__c.getRecordTypeInfosByName()
                                .get('Five 9').getRecordTypeId();
        List<Service_Statistics__c> stats = [   select Id, Five9_Current_Longest_Queue_Time__c
                                                from Service_Statistics__c
                                                where RecordTypeId =: five9RecordTypeId
                                                    and Five9_Type__c ='ACDStatus'
                                                    and Five9_Community__c =: comm
                                                    and Five9_Language__c =: lang];

        Decimal retVal = 0;
        if (stats.size() >0){
            retVal = (stats[0].Five9_Current_Longest_Queue_Time__c/60000).setscale(0, roundingMode.UP); 
        }

        if (retVal < 1){
            return Decimal.valueOf(Label.Community_Min_Wait_Time);
        } else {
            return retVal;
        }

    }

    /**
    * @description Make a call to get Live Agent Statistics from service stats sObject
    */
    public static Decimal getChatWaitTime(String lang, String comm){
        Id liveAgentRecordTypeId = Schema.SObjectType.Service_Statistics__c.getRecordTypeInfosByName()
                                .get('Live Agent').getRecordTypeId();
        List<Service_Statistics__c> stats = [   select Id, Live_Agent_Estimated_Wait_Time__c
                                                from Service_Statistics__c
                                                where RecordTypeId =: liveAgentRecordTypeId
                                                    and Live_Agent_Community__c =: comm 
                                                    and Live_Agent_Language__c =: lang];

        Decimal retVal = 0;
        if (stats.size() >0){
            retVal = (stats[0].Live_Agent_Estimated_Wait_Time__c/60).setscale(0, roundingMode.UP); 
        }

        if (retVal < 1){
            return Decimal.valueOf(Label.Community_Min_Wait_Time);
        } else {
            return retVal;
        }
    }
}