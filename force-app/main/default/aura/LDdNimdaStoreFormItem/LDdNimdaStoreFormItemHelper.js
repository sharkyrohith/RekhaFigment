({
    fireFormItemEvent: function(component, name, property, value, type, scale) {
        var formItemEvent = component.getEvent("LDdNimdaStoreFormItemEvent");
        formItemEvent.setParams({
            name: name,
            property: property,
            value: value,
            type: type,
            scale: scale
        });
        formItemEvent.fire();
    },
})