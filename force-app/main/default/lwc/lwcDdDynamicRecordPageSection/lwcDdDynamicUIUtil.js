/**
 * @author  : Sugan
 * @date : October 27th 2022
*  @description : A util class for storing section to field mapping
* field attributes explained
    apiName - api name of the field (enter value as blank for a blank space in the layout - also be sure to set isBlank=true for blank sections)
    required - to mark field as required on edit forms
    readOnly - to mark field as read only and also to show edit/pencil icon for fields, the icon is only a visual representation - once user clicks the edit icon - the record edit form shows fields in accordance with fls
    columnSpan - columnOptions.ONE_COLUMN (OR) columnOptions.TWO_COLUMN - to indicate if the field will just occupy one column or 2 columns
    isBlank - set to true for blank sections and false for all other

    ******** INSTRUCTIONS TO ADD NEW SECTION CASE PAGE **************************************************
    - Collect a list of api names of fields to be added to the section
    - Decide on a <SECTION_NAME> and add an entry in the "caseSectionToFieldsMapping" constant below for the section name
    - Add the fields based on the instructions in the below block on "adding new field to a section"
    *****************************************************************************************************

    ******** INSTRUCTIONS TO ADD NEW FIELD TO AN EXISTING SECTION ON CASE *********************************
    - Get the api name of the field to be added
    - Ctrl+f the section name and add a new entry to the field list (attributes explained above)
    ********************************************************************************************************

    ******** INSTRUCTIONS TO ADD FIELD MAPPING FOR A NEW OBJECT (besides case which exists below) *******************
    - Create new mapping JSON - similar to json for case caseSectionToFieldsMapping
    - Add new object to JSON mapping entry to "objToUIMapping"
    *****************************************************************************************************************

    */
/*****************************************************************************************************************************
*
* Imports
*
*****************************************************************************************************************************/


/*****************************************************************************************************************************
*
* Functional Consts
*
*****************************************************************************************************************************/
const columnOptions = {
    ONE_COLUMN: {"size":6,"variant":"label-inline"},
    TWO_COLUMN: {"size":12,"variant":"label-stacked"}
};
const caseSectionToFieldsMapping = {
    "Customer Information" :
    {
        fields:
            [{"apiName":"Account_name__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"ContactId","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"ContactPhone","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"DasherPhone__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"ContactEmail","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"CustomerPhone__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"SuppliedPhone","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"MerchantPhone__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Case At-a-Glance" :
    {
        fields:
            [{"apiName":"Language__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Country__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Initial_Queue_Name__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Customer_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Status","required":true,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"DeliveryUUID__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false
        },
            {"apiName":"Dispatch_URL__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Merchant_Profile__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Consumer_Profile__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Dasher_Profile__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_Type__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Resolution_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Resolution__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Invalid_Escalation__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"ParentId","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Invalid_Escalation_Reasons__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false},
            {"apiName":"Reopen_Reason__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    },
    "Chat Details" :
    {
        fields:
            [{"apiName":"Pre_Chat_Category__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Pre_Chat_Sub_Category__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Chat_Issue_Details__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Description","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Dasher Activation Kit Details" :
    {
        fields:
            [{"apiName":"Overture_Request_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Shipping_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"SKU__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"USPS_Tracking_Number__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Mx Equipment Request Details":
    {
        fields:
            [{"apiName":"Opportunity_Name__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Request_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Product_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Shipping_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Device_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Approved_Date__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Username2__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Password2__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Tracking_FedEx__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Ship_Date2__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tracking_StarTrack__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Tablet_Received_Date_2__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"USPS_Tracking_Number__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false},
            {"apiName":"Tablet_Serial_Number__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Reason_for_Replacement__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Printer_IMEI__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Broken_Tablet_Model__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Return_Replaced_Components__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    },
    "Merchant Operations":
    {
        fields:
            [{"apiName":"Store_ID__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_Category__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Account_Deck_Rank__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_PM__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Nimda_Link__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Mx_Support_Date_Completed__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Description_of_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    },
    "Menu Update Details":
    {
        fields:
            [{"apiName":"Requester__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Requester_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"SuppliedName","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Who_to_Contact_When_Complete__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Due_Date__c","required":false,"readOnly":true,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Length_of_Change__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"when_should_changes_go_live__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Date_to_Revert_Changes__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Menu_Update_Flow_Type_of_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Menu_Update_Flow_Update_Details__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Menu_s_Effected__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Single_Multi_Location_Menu_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Locations_Requiring_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Menu_Update_Flow_Type_of_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Menu_Update_Flow_Type_of_Update__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Menu_Attachment_URL__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Menu_URL_2__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"blank","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:true},
            {"apiName":"Menu_Team_Notes__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    },
    "POS Information Details":
    {
        fields:
            [{"apiName":"POS_Fallback_Protocol__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Activation_Method__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"POS_Integration_ID__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"POS_Go_Live_Date__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"POS_Integration_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Special_Character_Length__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Rejection_Reason_2__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Activation_Notes__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Rejection_Reason_Details__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Activations_Delay_Reason__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Insufficient_Information__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Proactive Outreach" :
    {
        fields:
            [{"apiName":"Proactive_Outreach_Trigger__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Outreach_Status__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Outreach_Feedback__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Outreach_Call_Attempt__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Alert Details":
    {
        fields:
            [{"apiName":"Status","required":true,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Back_to_Queue__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Customer_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"IsEscalated","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"DeliveryNo__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"OwnerId","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_PM__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Priority","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_Category__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"InternalCommentToFeed__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue_Type__c","required":true,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Issue__c","required":true,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false},
            {"apiName":"Resolution_Type__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false},
            {"apiName":"Resolution__c","required":false,"readOnly":false,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    },
    "Formstack Details" :
    {
        fields:
            [{"apiName":"Formstack_Category__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Formstack_Subcategory__c","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false},
            {"apiName":"Description","required":false,"readOnly":false,"columnSpan":columnOptions.ONE_COLUMN,isBlank:false}]
    },
    "Feature Logs" :
    {
        fields:
            [{"apiName":"Feature_Logs__c","required":false,"readOnly":true,"columnSpan":columnOptions.TWO_COLUMN,isBlank:false}]
    }};

    const objToUIMapping = {"Case" : caseSectionToFieldsMapping};
    /**
     * @decription
     * @param   {String} objectName - Api name of the object name
     * @param   {String} sectionName - Section name - this should match with one of the keys in the above map
     * @return  {json} - fields to be displayed on a section fetched based on the input section name
     */
    const getFieldsForSection = (objName, sectionName) => {
        return objToUIMapping[objName][sectionName];
    }

    export { getFieldsForSection };