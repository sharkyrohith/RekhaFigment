/**
 * @author Raju Lakshman
 * @date   Sep 16, 2021
 * @decription Wrapper used by frameworks utilizing the ddDateFilter lwc filter
 */

 public with sharing class CDdDateFilterWrapper {
    @AuraEnabled public DateTime minValue;
    @AuraEnabled public DateTime maxValue;
    @AuraEnabled public DateTime value;
    @AuraEnabled public String operator;
}