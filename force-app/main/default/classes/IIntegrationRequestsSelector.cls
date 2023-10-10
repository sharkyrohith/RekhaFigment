/********************************************************************************************************************
* @author Praveen
* @description inteface for IntegrationRequestsSelector
**************************************************************************************************************************************/

public interface IIntegrationRequestsSelector extends ISObjectsSelector{
    /**
     * @description Method for querying User records when you know their ids
     * @param Set<Id> Id The ids of the records to be returned
     * @return CDdMxIntegrationObject
     */
    CDdMxIntegrationObject selectById(Set<Id> ids);
    /**
     * @description Method for querying User records when you know their ids
     * @param Set<String> The status of the records to be returned
     * @param Set<String> sfdcOrg either figment or lemonade.
     * @param Integer days
     * @return CDdMxIntegrationObject
     */
    CDdMxIntegrationObject selectIntegrationRequestsByStatusAndOrg(Set<String> status,  Set<String> sfdcOrg, Integer days);
    /**
     * @description Method for querying integration records records when you know onboarding Id.
     * @param Set<String> onboardingIds,
     * @return A list of integration requests records records.using CDdMxIntegrationObject becuase the return type having objects or classes end with __x cannot be mocked.
     */
    CDdMxIntegrationObject selectIntegrationRequestsByOnboardingIds(Set<String> onboardingIds);
}