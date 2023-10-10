@isTest

public class CDdRecursionUtilsTest {

    // RecursionUtils Test methods
    
    public static testMethod void RecursionTest() {
        system.assertEquals(true, CDdRecursionUtils.isRunnable('CDdCustomMetadataTest'), 
            'This should be runnable the first time through');
        system.assertEquals(false,CDdRecursionUtils.isRunnable('CDdCustomMetadataTest'), 
            'This should NOT be runnable the next time through');
    }
    
}