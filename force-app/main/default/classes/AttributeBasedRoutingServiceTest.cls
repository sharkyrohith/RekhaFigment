@isTest
public class AttributeBasedRoutingServiceTest {

    @isTest
    static void testPushCasesForAttributeBasedRouting() {
        Id mockCaseId = Fake.generateId( Case.class );

        Id fakeRoutingConfigId = Fake.generateId( Routing_Configuration__mdt.class );

        Case mockCase = (Case) new Fake(Case.class)
                        .setField(Case.Id,mockCaseId)
                        .setField(Case.Routing_Destination__c,fakeRoutingConfigId)
                        .setField(Case.AccountId, Fake.generateId( Account.class ))
                        .toSObject();

        ServiceChannel mockServiceChannel = (ServiceChannel) new Fake(ServiceChannel.class)
                .setField(ServiceChannel.Id,Fake.generateId( ServiceChannel.class ))
                .setField(ServiceChannel.RelatedEntity,CDdSupportConstants.CASE_OBJECT_LABEL)
                .toSObject();

        Skill mockSk =  (Skill) new Fake(Skill.class)
            .setField(Skill.Id,Fake.generateId( Skill.class ))
            .setField(Skill.DeveloperName, 'TestSkill')
            .toSObject();

        Routing_Attribute_Defination__mdt mockRDef =  (Routing_Attribute_Defination__mdt) new Fake(Routing_Attribute_Defination__mdt.class)
            .setField(Routing_Attribute_Defination__mdt.Id,Fake.generateId( Routing_Attribute_Defination__mdt.class ))
            .setField(Routing_Attribute_Defination__mdt.Routing_Configuration__c,fakeRoutingConfigId)
            .setField(Routing_Attribute_Defination__mdt.Skill__c, 'TestSkill')
            .setField(Routing_Attribute_Defination__mdt.Skill_Level__c, 5)
            .setField(Routing_Attribute_Defination__mdt.Skill_Priority__c, 1)
            .toSObject();
        List<Routing_Attribute_Defination__mdt> lstMockRDef = new List<Routing_Attribute_Defination__mdt>{mockRDef};

        Attribute_Based_Routing_Setting__c rSetting = (Attribute_Based_Routing_Setting__c)new Fake(Attribute_Based_Routing_Setting__c.class)
        .setFakeId()
        .setField(Attribute_Based_Routing_Setting__c.Capacity_Weight__c,5)
        .setField(Attribute_Based_Routing_Setting__c.PushTimeout__c,20)
        .setField(Attribute_Based_Routing_Setting__c.Routing_Model__c,'LeastAvailable')
        .setField(Attribute_Based_Routing_Setting__c.Routing_Priority__c,1)
        .toSObject();

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        IAttributeBasedRoutingSettingSelector mockAttributeBasedSelector = (IAttributeBasedRoutingSettingSelector) mocks.mock(
            IAttributeBasedRoutingSettingSelector.class
        );
        ISkillSelector mockSkillSelector = (ISkillSelector) mocks.mock(
            ISkillSelector.class
        );
        IRoutingAttributeDefinationSelector mockRoutingAttributeSelector = (IRoutingAttributeDefinationSelector) mocks.mock(
            IRoutingAttributeDefinationSelector.class
        );
        IServiceChannelSelector mockServiceChannelSelector = (IServiceChannelSelector) mocks.mock(
            IServiceChannelSelector.class
        );

        mocks.startStubbing();
        mocks.when(mockAttributeBasedSelector.sObjectType()).thenReturn(Attribute_Based_Routing_Setting__c.SObjectType);
        mocks.when(mockAttributeBasedSelector.getInstance()).thenReturn(rSetting);
        mocks.when(mockRoutingAttributeSelector.sObjectType()).thenReturn(Routing_Attribute_Defination__mdt.SObjectType);
        mocks.when(mockRoutingAttributeSelector.selectActiveDefinationById(new Set<String>{fakeRoutingConfigId})).thenReturn(lstMockRDef);
        mocks.when(mockSkillSelector.sObjectType()).thenReturn(Skill.SObjectType);
        mocks.when(mockSkillSelector.selectAllSkills()).thenReturn(new List<Skill>{mockSk});
        mocks.when(mockServiceChannelSelector.sObjectType()).thenReturn(serviceChannel.SObjectType);
        mocks.when(mockServiceChannelSelector.selectByRelatedEntity(CDdSupportConstants.CASE_OBJECT_LABEL)).thenReturn(mockServiceChannel);
        mocks.stopStubbing();

        Application.UnitOfWork.setMock(mockUOW);

        try{
            Map<Id,Case> mapCaseIdCaseData = new Map<Id,Case>();
            mapCaseIdCaseData.put(mockCaseId,mockCase);
            Test.startTest();
            AttributeBasedRoutingService.pushCasesForAttributeBasedRouting(mapCaseIdCaseData);
            Test.stopTest();
        }
        catch(Exception e){
           System.assert(e instanceof DmlException);
        }
    }
}