/**
 * Created by Jeremy S. Johnson, Perficient, Inc.
 */

({
    init: function (cmp, event, helper) {
        helper.handleInit(cmp, event);
    },

    handleSave: function(cmp, event, helper) {
        helper.handleSave(cmp, event);
    },

    invoke : function(cmp, event, helper) {
        helper.handleChecks(cmp, event);
    },

    isRefreshed: function(component, event, helper) {
    },
});