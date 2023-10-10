/**
 * 
 * @author: Tia Xuan
 * @date: 2020-01
 * @description class for the prechat on community chat
 * 
 */
public without sharing class CDdCommunityPrechatController {

    @AuraEnabled
    public static CommunityPrechatWrapper initCommunityPrechat(String objName, 
                                                                String parentField, 
                                                                String childField){

        CommunityPrechatWrapper wrp = new CommunityPrechatWrapper(); 
        wrp.catPicklist = CDdCommunityHelper.getPicklistValues(objName, parentField);
        wrp.depPicklist = CDdCommunityHelper.getDependentPicklist(objName, parentField, childField); 
        wrp.showDasherW2 = CDdExperimentSvc.getFeatureFlag('Dasher_W__c');
        return wrp;
    }


    public class CommunityPrechatWrapper{
        @AuraEnabled
        public List<CDdCommunityHelper.PicklistEntryWrapper> catPicklist;
        @AuraEnabled
        public Map<String,List<CDdCommunityHelper.PicklistEntryWrapper>> depPicklist;
        @AuraEnabled
        public Boolean showDasherW2;

        public CommunityPrechatWrapper(){
            catPicklist = new List<CDdCommunityHelper.PicklistEntryWrapper>();
            depPicklist = new Map<String,List<CDdCommunityHelper.PicklistEntryWrapper>>();
            showDasherW2 = false;
        }
    }

}