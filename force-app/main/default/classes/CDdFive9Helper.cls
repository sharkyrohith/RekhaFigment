/**
 * 
 * @author: Tia Xuan
 * @date: 2019-08
 * @description class for CDdFive9Helper
 * 				helper class for five 9 statistics
 * 
 */
public without sharing class CDdFive9Helper {

    public static Id five9RTId = Schema.SObjectType.Service_Statistics__c
                                    .getRecordTypeInfosByName().get('Five 9').getRecordTypeId();
    /**
    * @description get five 9 statistic by type
    **/
    @future(callout=true)
    public static void getFive9Stats(String statsType){
        try {
            Five9_Setting__mdt setting = [  select  Username__c, 
                                                    Password__c,
                                                    Names__c
                                            from Five9_Setting__mdt
                                            where MasterLabel =: statsType];
            
            CDdFive9SupervisorWS.WsSupervisorPort port = new CDdFive9SupervisorWS.WsSupervisorPort();
            String creds = setting.Username__c + ':' + setting.Password__c;
            String credsBase64 = EncodingUtil.base64Encode(Blob.valueof(creds));
            port.inputHttpHeaders_x = new Map<String, String>();
            port.inputHttpHeaders_x.put('Authorization', 'Basic ' + credsBase64);
            port.timeout_x = 60000;
            CDdFive9SupervisorWS.viewSettings vSetting = new CDdFive9SupervisorWS.viewSettings();
            vSetting.forceLogoutSession = true; 
            vSetting.idleTimeOut = 60;
            vSetting.statisticsRange = 'CurrentDay';
            vSetting.rollingPeriod = 'Today';
            vSetting.timeZone = -25200000; 
            port.setSessionParameters(vSetting);

            CDdFive9SupervisorWS.row rows = port.getColumnNames(statsType);
            CDdFive9SupervisorWS.statistics retValue = port.getStatistics(statsType, rows, false);
            port.closeSession();
                    
            List<Service_Statistics__c> retVals = fillStatsObj(statsType, retValue);
            List<Service_Statistics__c> existingVals =  [   select Id 
                                                            from Service_Statistics__c 
                                                            where Five9_Type__c =: statsType 
                                                                and RecordTypeId =: five9RTId];
            delete existingVals;
            
            List<Service_Statistics__c> rowsToInsert = new List<Service_Statistics__c>();

            Set<String> names = new Set<String>(setting.Names__c.split(','));
            for (Service_Statistics__c stat : retVals){
                if (names.contains(stat.Five9_Skill_Name__c) || Test.isRunningTest()){
                    rowsToInsert.add(stat);
                }
            }

            insert rowsToInsert;
        } catch (Exception e){
            CDdErrorUtilities.createApexLogs(new List<String>{e.getMessage()}, 'CDdFive9Helper');
        }
    }

    /**
    * @description fill the stats object with stat results
    **/
    private static List<Service_Statistics__c> fillStatsObj(String statsType, CDdFive9SupervisorWS.statistics statObj){


        List<Service_Statistics__c> retVal  = new List<Service_Statistics__c>();
        String[] colNames = statObj.columns.values.data;
        for (CDdFive9SupervisorWS.row row : statObj.rows){
            Service_Statistics__c statRow = new Service_Statistics__c();
            statRow.RecordTypeId = five9RTId;
            statRow.Five9_Type__c = statsType;
            for (Integer colIndex =0; colIndex < colNames.size(); colIndex++ ){ 
                if (colIndex ==0){
                    statRow.Five9_Skill_Name__c = row.values.data[colIndex];
                }
                if (statsType == 'ACDStatus'){ 
                    if (colNames[colIndex] == 'Longest Queue Time'){
                        statRow.Five9_Longest_Queue_Time__c = Integer.valueOf(row.values.data[colIndex]);
                    }
                    if (colNames[colIndex] == 'Current Longest Queue Time'){
                        statRow.Five9_Current_Longest_Queue_Time__c = Double.valueOf(row.values.data[colIndex]);
                    }
                }
            }
            retVal.add(statRow);     
        }
        return retVal;
    }
}