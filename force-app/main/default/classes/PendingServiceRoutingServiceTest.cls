@isTest
public class PendingServiceRoutingServiceTest {

    @isTest
    static void testCreateSkillBasedPSR() {
        Id mockCaseId = Fake.generateId( Case.class );

        List<PendingServiceRoutingService.PSRSkillBasedWrapper> lstPSRWrap = new List<PendingServiceRoutingService.PSRSkillBasedWrapper>();

        PendingServiceRoutingService.PSRSkillBasedWrapper psr =
            new PendingServiceRoutingService.PSRSkillBasedWrapper(5,false,'LeastActive',1,Fake.generateId(ServiceChannel.class),mockCaseId,10);
            psr.lstSkills.add(new PendingServiceRoutingService.PSRSkillRequirementWrapper(Fake.generateId(Skill.class),5.0,1,false));
            psr.lstSkills.add(new PendingServiceRoutingService.PSRSkillRequirementWrapper(Fake.generateId(Skill.class),5.0,1,true));
        lstPSRWrap.add(psr);

        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork mockUOW = (fflib_ISObjectUnitOfWork) mocks.mock(fflib_ISObjectUnitOfWork.class);
        Application.UnitOfWork.setMock(mockUOW);
        String errorMsg = PendingServiceRoutingService.createSkillBasedPSR(lstPSRWrap);
        ((fflib_ISObjectUnitOfWork) mocks.verify(mockUOW, mocks.times(1)))
        .registerNew(
            fflib_Match.sObjectWith(
                new Map<SObjectField, Object>{
                    PendingServiceRouting.WorkItemId => mockCaseId,
                    PendingServiceRouting.isReadyForRouting => true
                }
            )
        );
        System.assertEquals(CDdCoreConstants.BLANK_STRING,errorMsg,'error message should be blank');
    }
}