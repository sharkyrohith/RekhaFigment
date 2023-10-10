({
    isChangeOfOwnership : function(component){
        return component.get("v.CHANGE_OF_OWNERSHIP_ACTIONS").indexOf(component.get("v.value")) > -1;
    },
    fireNimdaSyncEvent: function(component, step, version) {
        var nimdaSyncEvent = component.getEvent("LDdNimdaSyncEvent");
        nimdaSyncEvent.setParams({
            step: step
            , version: parseInt(version)
            , isChangeOfOwnership: this.isChangeOfOwnership(component)
        });
        nimdaSyncEvent.fire();
    },
})