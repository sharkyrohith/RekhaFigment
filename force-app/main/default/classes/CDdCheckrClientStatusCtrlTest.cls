@isTest
public class CDdCheckrClientStatusCtrlTest {
    static testMethod void testEmailValidation() {
        PageReference pageRef = Page.PDdCheckrClientStatus;
		Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('email', 'thisshouldfail');
        CDdCheckrClientStatusCtrl ctrl = new CDdCheckrClientStatusCtrl();
		PageReference test1 = ctrl.searchCheckr();
        System.assertEquals(test1, null);
		
		ApexPages.currentPage().getParameters().put('email', 'thisshouldwork@gmail.com');
        PageReference test2 = ctrl.searchCheckr();
        System.assertNotEquals(test2, null);
        System.assertEquals(test2.getUrl(), '/apex/pddcheckrclientstatusresult?email=thisshouldwork%40gmail.com');
    }
}