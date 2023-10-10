/**
 * @description       :
 * @author            : Jose Vega
 * @last modified on  : 03-07-2023
 * @last modified by  : Jose Vega
**/
public class CDdCaseRelatedCasesCtrl {

    public static Map<String, Schema.SObjectType> SOBJECT_TYPES = Schema.getGlobalDescribe();

    @AuraEnabled
    public static DeliveryCasesWrapper getRelatedCases(String relatedField, String caseId, String fields, Integer numRec, string addFilter){
        DeliveryCasesWrapper wrp = new DeliveryCasesWrapper();

        String sqlString =  'select Id, CaseNumber,';
        sqlString +=            relatedField;
        sqlString +=        ' from Case ';
        sqlString +=        ' where  Id =: caseId ';

        Case c = Database.query(sqlString);
        wrp.currentCase = c;

        String relId = (String) c.get(relatedField);
        if (String.isNotBlank(relId)){
            sqlString =  'select Id,';
            sqlString +=            fields;
            sqlString +=        ' from Case ';
            sqlString +=        ' where ' + relatedField + ' =: relId ';
            sqlString +=        '   and Id !=: caseId ';
            if(addFilter != null && String.isNotBlank(addFilter)){
				sqlString += ' and '+ addFilter;
            }
            sqlString +=        ' order by CreatedDate DESC ';
            sqlString +=        ' limit ' + numRec;

            wrp.caseList = Database.query(sqlString);
        }

        wrp.fieldList = new List<FieldWrapper>();
        List<String> fldList = fields.split(',');
        Map<String, Schema.SObjectField> fMap = SOBJECT_TYPES.get('case').getDescribe().Fields.getMap();
        for (String fld : fldList){
            Schema.DescribeFieldResult dfr = fMap.get(fld).getDescribe();
            FieldWrapper fWrp = new FieldWrapper(dfr);
            wrp.fieldList.add(fWrp);
        }

        return wrp;
    }

    @AuraEnabled
    public static void mergeCases(String caseId, String parentCaseId){
        Case c = new Case();
        c.Id = caseId;
        c.parentId = parentCaseId;
        update c;
    }

    public class DeliveryCasesWrapper{
        @auraEnabled
        public Case currentCase             {get; set;}
        @auraEnabled
        public List<Case> caseList          {get; set;}
        @auraEnabled
        public List<FieldWrapper> fieldList {get; set;}
    }

    public class FieldWrapper{
        @auraEnabled
        public String name  {get; set;}
        @auraEnabled
        public String label {get; set;}
        @auraEnabled
        public String type  {get; set;}

        public FieldWrapper(Schema.DescribeFieldResult res){
            name = res.name;
            label = res.label;
            type = String.valueOf(res.type);
        }
    }
}

/*
Case Number  CaseNumber
Customer Type Customer_Type__c
Account Email Account_Email__c
Status Status
Date/Time Opened CreatedDate
Subject Subject
Issue Category Issue_Type__c
Issue Issue__c
Delivery No (Formula) DeliveryNoFF__c

CaseNumber,Customer_Type__c,Account_Email__c,Status,CreatedDate,Subject,Issue_Type__c,Issue__c,DeliveryNoFF__c
*/