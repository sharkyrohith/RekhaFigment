/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

({
    handleInit: function(cmp, event) {
        this.defineColumns(cmp)

        let action = cmp.get("c.getCases");
        action.setParams({ caseId : cmp.get("v.recordId") });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                cmp.set("v.data", response.getReturnValue());
            } else {
                console.error(response.getState());
            }
        });

        $A.enqueueAction(action);
    },

    defineColumns: function(cmp) {
        cmp.set("v.columns", [
            { label: "Case Number",     fieldName: "ClaimLink", type: "url", typeAttributes: { label: { fieldName: "ClaimNo" }, target:"_blank" }, wrapText: true, initialWidth: 125 },
            { label: "Opportunity",     fieldName: "OpportunityLink", type: "url", wrapText: true, typeAttributes: { label: { fieldName: "Opportunity_Name_External_Use" }, target:"_blank" }},
            { label: "Status",          fieldName: "Status", wrapText: true, initialWidth: 125 },
            { label: "Shipment Status", fieldName: "Tablet_Shipment_Status", wrapText: true },
            { label: "Request Type",    fieldName: "Request_Type", wrapText: true },
            { label: "Ship Date",       fieldName: "Tablet_Ship_Date2", type: "date", typeAttributes: { month: "2-digit", day: "2-digit", year: "2-digit", hour: "2-digit", minute: "2-digit" }, wrapText: true },
            { label: "Received Date",   fieldName: "Tablet_Received_Date_2", type: "date", typeAttributes: { month: "2-digit", day: "2-digit", year: "2-digit", hour: "2-digit", minute: "2-digit" }, wrapText: true },
            { label: "Tablet IMEI",     fieldName: "Tablet_SIM_Card_Number", wrapText: true },
            { label: "Track Status",    fieldName: "Track_Status", type: "url", typeAttributes: { label: "Click Here", target:"_blank" }, wrapText: true }
        ]);
    },
});