({
    showProgress: function (component) {
        component.set('v.progress', 0);
        let increment = parseInt(component.get("v.increment"));
        let refreshInterval = parseInt(component.get("v.interval"));
        var interval = setInterval($A.getCallback(function () {
            var progress = component.get('v.progress');
            component.set('v.progress', progress === 100 ? clearInterval(interval) : progress + increment);
        }), refreshInterval);
    }
})