/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 6/14/2020.
 *
 * Utility class for retrieving Case record types in a strongly-typed manner. The Type enum
 * represents the record type DeveloperName.
 */

public class CDdRecordTypeCase {
    public enum Type {
        Account_Management,
        API,
        Bulk_Upload_Request,
        Caviar_Onboarding,
        Caviar_Support,
        Customer,
        DTB,
        Menu_Update_Request_Web,
        Mx_Marketing_Requests,
        Mx_Tools_Requests,
        Onboarding_Manager_Handoff,
        Photoshoot_Processing,
        POS_Integrations,
        POS_Support,
        Post_Sale_Activations,
        Support_Tool_Requests,
        Tablet_Requests
    }

    public static Id getId(CDdRecordTypeCase.Type type) {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(type.name()).getRecordTypeId();
    }

    public static Id accountManagement() {
        return getId(Type.Account_Management);
    }

    public static Id api() {
        return getId(Type.API);
    }
    public static Id bulkUploadRequest() {
        return getId(Type.Bulk_Upload_Request);
    }

    public static Id caviarOnboarding() {
        return getId(Type.Caviar_Onboarding);
    }

    public static Id caviarSupport() {
        return getId(Type.Caviar_Support);
    }

    public static Id customer() {
        return getId(Type.Customer);
    }

    public static Id dtb() {
        return getId(Type.DTB);
    }

    public static Id menuUpdateRequestWeb() {
        return getId(Type.Menu_Update_Request_Web);
    }

    public static Id mxMarketingRequests() {
        return getId(Type.Mx_Marketing_Requests);
    }

    public static Id mxToolsRequests() {
        return getId(Type.Mx_Tools_Requests);
    }

    public static Id onboardingManagerHandoff() {
        return getId(Type.Onboarding_Manager_Handoff);
    }

    public static Id photoshootProcessing() {
        return getId(Type.Photoshoot_Processing);
    }

    public static Id posIntegrations() {
        return getId(Type.POS_Integrations);
    }

    public static Id posSupport() {
        return getId(Type.POS_Support);
    }

    public static Id postSaleActivations() {
        return getId(Type.Post_Sale_Activations);
    }

    public static Id supportToolRequests() {
        return getId(Type.Support_Tool_Requests);
    }

    public static Id tabletRequests() {
        return getId(Type.Tablet_Requests);
    }
}