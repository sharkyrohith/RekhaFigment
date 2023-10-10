/**
 * @author DoorDash
 * @date 03/09/2023
 * @description Selector class for Bat_To_Milestone_Status_Mapping__mdt custom metadata.
 */
public interface IBatToMilestoneStatusMappingSelector extends fflib_ISObjectSelector { 

    /**
     * @description It fetches all records of Milestone Status Mapping metadata.
     * @return List<Bat_To_Milestone_Status_Mapping__mdt> - Returns list of metadata records
     */
    List<Bat_To_Milestone_Status_Mapping__mdt> getAllValues();

    /**
     * @description It is for getting the fields of Bat_To_Milestone_Status_Mapping__mdt.
     * @return List<Schema.SObjectField> - Returns Bat_To_Milestone_Status_Mapping__mdt fields
     */
    List<Schema.SObjectField> getSObjectFieldList();
}