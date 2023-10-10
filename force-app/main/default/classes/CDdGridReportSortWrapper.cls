/*
 * @author: Raju Lakshman
 * @date : October 2021
 * @description: Wrapper for Grid Report Sort Info.
 */
public without sharing class CDdGridReportSortWrapper {
    @AuraEnabled public String sortedBy {get;set;}
    @AuraEnabled public String sortDirection {get;set;}
    @AuraEnabled public String sortNulls {get;set;}
}