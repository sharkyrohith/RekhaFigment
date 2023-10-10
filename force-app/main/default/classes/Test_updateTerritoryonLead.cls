@isTest
public class Test_updateTerritoryonLead {

    private static testmethod void updateTerritoryonLead_testMethod(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User u = new User();
       	u.FirstName = 'Test';
       	u.LastName  = 'User12';
       	u.Email     = 'testsuser@tests.com';
       	u.Username  = 'testsuser@tests.com';
       	u.Alias     = 'test23';
       	u.ProfileId = p.id;
       	u.TimeZoneSidKey    = 'America/Denver';
       	u.LocaleSidKey      = 'en_US';
       	u.EmailEncodingKey  = 'UTF-8';
       	u.LanguageLocaleKey = 'en_US';
        insert u;
        
        Territory__c tr = new Territory__c ();
        tr.name = 'Test Tr';
        tr.Zip_Codes__c = '12345,14567,78741';
        insert tr;
        
        Territory_Assignment__c ta = new Territory_Assignment__c();
        ta.User__c = u.id;
        ta.Territory__c = tr.id;
        insert ta;
        
        System.runAs(u){
     
        Lead l = new Lead();
        l.LastName = 'test LastName';
        l.FirstName = 'First Name';
        l.Company = 'Test Company';
        l.Street = '123 Mulberry Ln';
        l.postalCode = '12345';
        l.Phone = '(800) 555-1234';
        insert l;
        
        l.Territory__c = null;
        l.PostalCode = '78741';
        update l;
        }
        
        try{
        Lead l2 = new Lead();
        l2.LastName = 'test LastName';
        l2.FirstName = 'First Name';
        l2.Company = 'Test Company';
        l2.Street = '123 Mulberry Ln';
        l2.postalCode = '12345';
        l2.Phone = '(900) 555-5678';
        insert l2;
        }
        catch(Exception e){
            
        }
        
    }

}