public inherited sharing class AttributeBasedRoutingServiceImpl implements IAttributeBasedRoutingService{

     /**
     * @description : Method to push cases for Skill based routing
     * @param mapCaseIdCase - Map of Case Id and Case Data
     * @return None
    */
    public void pushCasesForAttributeBasedRouting(Map<Id,Case> mapCaseIdCaseData){
        Id serviceChannelId = ServiceChannelsSelector.newInstance().selectByRelatedEntity(CDdSupportConstants.CASE_OBJECT_LABEL).Id;
        //check criteria on each case and get routing Destination
        Attribute_Based_Routing_Setting__c psrAtt = AttributeBasedRoutingSettingsSelector.newInstance().getInstance();
        Set<String> setConfigIds = new Set<String>();
        List<PendingServiceRoutingService.PSRSkillBasedWrapper> lstPSRWrapper = new List<PendingServiceRoutingService.PSRSkillBasedWrapper>();
        Integer cWeight = Integer.valueOf(psrAtt.Capacity_Weight__c);
        String rModel = psrAtt.Routing_Model__c;
        Integer rPrioirty = Integer.valueOf(psrAtt.Routing_Priority__c);
        Integer pTimeOut = Integer.valueOf(psrAtt.PushTimeout__c);
        for (Case caseVar : mapCaseIdCaseData.values()) {
            setConfigIds.add(caseVar.Routing_Destination__c);
            PendingServiceRoutingService.PSRSkillBasedWrapper psr =
            new PendingServiceRoutingService.PSRSkillBasedWrapper(cWeight,false,rModel,rPrioirty,serviceChannelId,caseVar.Id,pTimeOut);
            //PSR record wrapper
            lstPSRWrapper.add(psr);
        }
        if (lstPSRWrapper.isEmpty()){
            return;
        }
        try{
            Map < String, Id > mapSkillId = new Map < String, Id >();
            Map<Id,List<Routing_Attribute_Defination__mdt>> mapConfAttribute = new Map<Id,List<Routing_Attribute_Defination__mdt>>();

            //Get the map of skill
            for (Skill objSkill : SkillsSelector.newInstance().selectAllSkills()){
                mapSkillId.put( objSkill.DeveloperName,objSkill.Id );
            }
            if (setConfigIds.isEmpty()){
                return;
            }
            //Find out the skills based on Routing Config stamped on case
            for(Routing_Attribute_Defination__mdt rInfo:RoutingAttributeDefinationsSelector.newInstance().selectActiveDefinationById(setConfigIds)){
                if(!mapConfAttribute.containsKey(rInfo.Routing_Configuration__c)){
                    mapConfAttribute.put(rInfo.Routing_Configuration__c,new List<Routing_Attribute_Defination__mdt>());
                }
                mapConfAttribute.get(rInfo.Routing_Configuration__c).add(rInfo);
            }

            //Loop over PSR wrapper for Skill Requirement
            for (PendingServiceRoutingService.PSRSkillBasedWrapper objPSR : lstPSRWrapper) {
                List<PendingServiceRoutingService.PSRSkillRequirementWrapper> lstSkills = new
                List<PendingServiceRoutingService.PSRSkillRequirementWrapper>();
                sObject caseRec = mapCaseIdCaseData.get(objPSR.WorkItemId);
                String preferredVendor = (String) caseRec.get('Preferred_Vendor__c');
                Id rConfigId = (Id) caseRec.get('Routing_Destination__c');
                if(String.isNotBlank(preferredVendor)){
                    //This need to see skillName should be VendorName+Skillname???
                    lstSkills.add(new PendingServiceRoutingService.PSRSkillRequirementWrapper(mapSkillId.get(preferredVendor),0.0,0,false));
                }
                for(Routing_Attribute_Defination__mdt skillObj : mapConfAttribute.get(rConfigId)){
                    lstSkills.add(new PendingServiceRoutingService.PSRSkillRequirementWrapper(mapSkillId.get(skillObj.Skill__c),skillObj.Skill_Level__c,Integer.valueOf(skillObj.Skill_Priority__c),skillObj.Additional_Skill__c));
                }
                objPSR.lstSkills = lstSkills;
            }
            //Pass the wrapper for PSR and Skill creation
            PendingServiceRoutingService.createSkillBasedPSR(lstPSRWrapper);
        }
        catch(Exception ex){
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            String errorMessage = CDdErrorUtilities.getFormattedException('AttributeBasedRoutingServiceImpl' + ':' + 'pushCasesForAttributeBasedRouting', ex);
            for (Case caseVar : mapCaseIdCaseData.values()) {
                caseVar.Feature_Logs__c = CDdErrorUtilities.constructFeatureLog('ATTRIBUTE BASED ROUTING EXCEPTION', errorMessage, String.isBlank(caseVar.Feature_Logs__c));
                uow.registerDirty(caseVar);
            }
            uow.commitWork();
            CDdErrorUtilities.publishException('AttributeBasedRoutingServiceImpl', 'pushCasesForAttributeBasedRouting', ex);
        }
    }

}