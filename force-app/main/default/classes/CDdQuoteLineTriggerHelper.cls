/**
* @author: Gregory Dorsey (Cognizant)
* @date: 05-2021    
* @description: Trigger Helper for Salesforce CPQ Quote Lines          
*/ 
public with sharing class CDdQuoteLineTriggerHelper {    
    /**
     * @description updates the quotes to have certain fields updated based on the quotes status
     */
    public static void updateQuoteFields(List<SBQQ__QuoteLine__c> quoteLines){
        if(!CDdRecursionUtils.isRunnable('CDdQuoteLineTrigger_updateQuoteFields')){
            return;
        }
        
        Map<String, SBQQ__Quote__c> quoteMap = new Map<String, SBQQ__Quote__c>( [ SELECT 
                                                                                 	Id, Weekly_Tablet_Fee__c, Weekly_Printer_Fee__c, Service_Fee__c, 
                                                                                 	Pricing_Tier__c, SBQQ__Status__c
                                                                                 	FROM SBQQ__Quote__c
                                                                                 	WHERE Id IN : getFieldSet(quoteLines, Schema.SBQQ__QuoteLine__c.SBQQ__Quote__c)]);

        for(SBQQ__QuoteLine__c quoteLine : quoteLines){
            SBQQ__Quote__c quoteToUse = quoteMap.get(quoteLine.SBQQ__Quote__c);
            if(quoteLine.DD_Custom_ID__c == 'MKTPL-0000111'){
                quoteToUse.Weekly_Tablet_Fee__c = quoteLine.SBQQ__NetTotal__c;
            }
            if(quoteLine.DD_Custom_ID__c == 'MKTPL-0000114'){
                quoteToUse.Weekly_Printer_Fee__c = quoteLine.SBQQ__NetTotal__c;
            }
            if(quoteLine.DD_Custom_ID__c == 'MKTPL-0000134'){
                quoteToUse.Service_Fee__c = quoteLine.Final_Commission__c;
            }
            if(quoteLine.DD_Custom_ID__c == 'MKTPL-0000119'){
                quoteToUse.Pricing_Tier__c = quoteLine.CPQ_Pricing_Tier__c;
            }
            quoteMap.put(quoteToUse.Id, quoteToUse);
        }

        update quoteMap.values();
    }

	
	public static Set<String> getFieldSet(List<SObject> sObjectList, Schema.SObjectField field){
        
        return new Set<String>(getFieldList(sObjectList, String.valueOf(field)));
        
    }
    
    public static List<String> getFieldList(List<SObject> sObjectList, String field){
        
        List<String> stringList = new List<String>();
        
            for(SObject sObjectRecord : sObjectList){
                
                if(sObjectRecord.get(field)!=null){
                    stringList.add(String.valueOf(sObjectRecord.get(field)));
                }
                
            }
        
        return stringList;
    }    
}