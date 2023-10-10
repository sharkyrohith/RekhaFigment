/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Wrapper used by frameworks utilizing the ddNumberFilter lwc filter
 */
public with sharing class CDdNumberFilterWrapper {
    @AuraEnabled public Decimal minValue;
    @AuraEnabled public Decimal maxValue;
    @AuraEnabled public Decimal value;
    @AuraEnabled public String operator;
}