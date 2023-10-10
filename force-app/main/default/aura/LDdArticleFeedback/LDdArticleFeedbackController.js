({
    doInit: function(component, event, helper) {
        var pickMap = [
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Add_More_Info"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Add_More_Info")},
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Make_It_Easier"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Make_It_Easier")},
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Fix_An_Error"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Fix_An_Error")},
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Dont_Like"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Dont_Like")},
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Steps"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Steps")},
            {label: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Other"), value: $A.get("$Label.c.DdCommunity_Article_Feedback_Improve_Other")}

        ];
        component.set("v.pickMap", pickMap);

    },

    onYesClick : function(component, event, helper) {
        component.set("v.yesORno",true);
        helper.handleYesClick(component, event, helper);
    },

    onNoClick : function(component, event, helper) {
        component.set("v.yesORno", false);
    },

    onSubmit : function(component, event, helper) {
        helper.handleNoClick(component, event, helper);
    },

    checkLength : function (component, event) {
        var len = 0;
        var value = component.get("v.moreInfo");
        console.log(value.length);
        len = (value.length>0) ? value.length : 0;
        document.getElementById('lengthDiv').innerHTML = (len) + ' ' + component.get("v.mLength");
    }
})