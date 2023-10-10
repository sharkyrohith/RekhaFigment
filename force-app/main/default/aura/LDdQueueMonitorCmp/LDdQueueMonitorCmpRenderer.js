({
    unrender: function (component,helper) {
        this.superUnrender();

        window.clearInterval(component.get("v.membershipIntervalId"));
        window.clearInterval(component.get("v.membershipCacheIntervalId"));
    }
})