({
	afterRender  : function(cmp, helper){
        this.superAfterRender();
        setTimeout(function() {
            var pageTitle = window.document.title;
            cmp.set("v.pageTitle", pageTitle);
            cmp.set("v.isDashPassPage", pageTitle.includes('DashPass'));
        }, 3000);


    }
})