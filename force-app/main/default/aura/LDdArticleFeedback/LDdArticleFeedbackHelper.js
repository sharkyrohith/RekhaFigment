({
    handleYesClick : function(component, event, helper) {

        var lang = helper.getURLParam("language");
        var comm = component.get("v.community");
        var action = component.get("c.handleYesClickServer");
        action.setParams({
            articleId : component.get("v.recordId"),
            lang : lang,
            comm : comm
        });
        action.setCallback(this, function(response){
            console.log(response.getState());
            if(response.getState()=="SUCCESS"){
                component.set("v.showMessage", true);
            } else {
                var errors = response.getError();
                var errorMsg = "";
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg = errors[0].message;
                    }
                    if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0]) {
                        errorMsg = errors[0].pageErrors[0].message;
                    }
                } else {
                    errorMsg ="Unknown error";
                }
                console.log("ERROR:" + errorMsg);
                helper.showToast("ERROR", errorMsg);
            } 
        });

        $A.enqueueAction(action);
    },
    handleNoClick : function(component, event, helper) {
        var lang = helper.getURLParam("language");
        var comm = component.get("v.community");
        var action = component.get("c.handleNoClickServer");
        action.setParams({
            articleId : component.get("v.recordId"),
            option : component.get("v.radioValue"),
            mInfo : component.get("v.moreInfo"),
            lang : lang,
            comm : comm
        });
        action.setCallback(this, function(response){
            console.log(response.getState());

            if(response.getState()=="SUCCESS"){
                component.set("v.showMessage", true);
            } else {
                var errors = response.getError();
                var errorMsg = "";
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg =errors[0].message;
                    }
                    if (errors[0] && errors[0].pageErrors && errors[0].pageErrors[0]) {
                        errorMsg =errors[0].pageErrors[0].message;
                    }
                } else {
                    errorMsg ="Unknown error";
                }
                console.log("ERROR:" + errorMsg);
                helper.showToast("ERROR", errorMsg);
            } 
        });

        $A.enqueueAction(action);
    },
    getURLParam : function (parameterName) {
        var result = null,
            tmp = [];
        location.search
            .substr(1)
            .split("&")
            .forEach(function (item) {
              tmp = item.split("=");
              if (tmp[0] === parameterName) result = decodeURIComponent(tmp[1]);
            });
        return result;
    },
    showToast : function(component, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": msg
        });
        toastEvent.fire();
    }
})