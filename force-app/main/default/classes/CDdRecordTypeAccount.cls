/**
 * Created by Jeremy S. Johnson, Perficient Inc., on 6/14/2020.
 *
 * Utility class for retrieving Account record types in a strongly-typed manner. The Type enum
 * represents the record type DeveloperName.
 */

public class CDdRecordTypeAccount {
    public enum Type {
        Business_Development,
        Corp_Dev_Company,
        Corporate_Customers,
        Dasher,
        DoorDash_Drive,
        Enterprise_Drive,
        Enterprise_Marketplace,
        Grandparent_Account,
        Parent_Account,
        PersonAccount,
        Prospect
    }

    public static Id getId(Type type) {
        return Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(type.name()).getRecordTypeId();
    }

    public static Id businessDevelopment() {
        return getId(Type.Business_Development);
    }

    public static Id corpDevCompany() {
        return getId(Type.Corp_Dev_Company);
    }

    public static Id corporateCustomers() {
        return getId(Type.Corporate_Customers);
    }

    public static Id dasher() {
        return getId(Type.Dasher);
    }

    public static Id doorDashDrive() {
        return getId(Type.DoorDash_Drive);
    }

    public static Id enterpriseDrive() {
        return getId(Type.Enterprise_Drive);
    }

    public static Id enterpriseMarketplace() {
        return getId(Type.Enterprise_Marketplace);
    }

    public static Id grandparentAccount() {
        return getId(Type.Grandparent_Account);
    }

    public static Id parentAccount() {
        return getId(Type.Parent_Account);
    }

    public static Id personAccount() {
        return getId(Type.PersonAccount);
    }

    public static Id prospect() {
        return getId(Type.Prospect);
    }
}