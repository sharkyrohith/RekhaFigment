@isTest
private class Utilities_Test {
    @isTest
    private static void getInstance(){
        String instance = '';
        Organization o = [SELECT OrganizationType, InstanceName FROM Organization limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;

        //Set this header to test it
        ApexPages.currentPage().getHeaders().put('Host', insName+'.visual.force.com');

        if(orgType == 'Developer Edition'|| insName.startsWithIgnoreCase('cs')){
            List<String> parts = ApexPages.currentPage().getHeaders().get('Host').split('\\.');
            instance = parts[parts.size() - 4] + '.';
        }

        System.debug('instance:' + instance);
        System.debug('Utilities.getInstance():' + Utilities.getInstance());
        System.assertEquals(instance, Utilities.getInstance());
    }
    @isTest
    private static void getSubdomainPrefix(){
        Organization o = [SELECT OrganizationType, InstanceName FROM Organization limit 1];
        String orgType = o.OrganizationType;
        String insName = o.InstanceName;

        //This will always be empty unless it's sandbox
        if(insName.startsWithIgnoreCase('cs')){
            System.assertNotEquals('', Utilities.getSubdomainPrefix());
        } else {
            System.assertEquals('', Utilities.getSubdomainPrefix());
        }
    }

}