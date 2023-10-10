/**
 * @description       : Test for the Chatter Post Notes Template object
 * @author            : Jose Vega
 * @last modified on  : 05-14-2022
 * @last modified by  : Jose Vega
**/
@isTest public with sharing class CDdCPNTTriggerHandlerTest {
    @isTest
    static void testChatterPostNotesTemplateInsert() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Test.startTest();
            Chatter_Post_Notes_Template__c cpnt = new Chatter_Post_Notes_Template__c(Body__c = 'hello world', Active__c = true);
            insert cpnt;
            Test.stopTest();
            cpnt = [SELECT Id, Body__c FROM Chatter_Post_Notes_Template__c];
            String cpntBody = ChatterPostNotesTemplateCache.getChatterPostNotesTemplateBody(cpnt.Id);
            System.assertEquals('hello world', cpntBody, 'Body should be hello world');
        }
    }
    
    @isTest
    static void testChatterPostNotesTemplateUpdate() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Test.startTest();
            Chatter_Post_Notes_Template__c cpnt = new Chatter_Post_Notes_Template__c(Body__c = 'hello world', Active__c = true);
            insert cpnt;
            cpnt.Body__c = 'good morning';
            update cpnt;
            Test.stopTest();
            cpnt = [SELECT Id, Body__c FROM Chatter_Post_Notes_Template__c];
            String cpntBody = ChatterPostNotesTemplateCache.getChatterPostNotesTemplateBody(cpnt.Id);
            System.assertEquals('good morning', cpntBody, 'Body should be good morning because it was updated.');
        }
    }

    @isTest
    static void testChatterPostNotesTemplateDelete() {
        User testUser = TDdUserFactory.createUsersWithoutRole(1,null, false)[0];
        System.runAs(testUser){
            Test.startTest();
            Chatter_Post_Notes_Template__c cpnt = new Chatter_Post_Notes_Template__c(Body__c = 'hello world', Active__c = true);
            insert cpnt;
            Id cpntId = cpnt.Id;
            delete cpnt;
            Test.stopTest();
            String cpntBody = ChatterPostNotesTemplateCache.getChatterPostNotesTemplateBody(cpntId);
            System.assertEquals(null, cpntBody, 'Body should be null');
        }
    }
}