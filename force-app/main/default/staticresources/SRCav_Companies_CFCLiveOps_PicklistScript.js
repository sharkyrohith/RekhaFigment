    
    var interId, region;

    if (window.location.href.indexOf('emailsupport') != -1){
        interId = setInterval(init, 100);
    } 

    function init() {
        region = document.getElementById("Caviar_Service_Region__c");
		deInit();
    };
    
    function deInit(){
        clearInterval(interId);
    }
    
    function catChange(){
        var catopts = [{label:"-None-", value:"", selected:true}];
        region.options = [];
        
        addOption(catopts,"Los Angeles");
        addOption(catopts,"New York");
        addOption(catopts,"Palo Alto");
        addOption(catopts,"San Francisco");                
        addOption(catopts,"San Jose");

        region.options= catopts;
        region.value = "";
        region.focus();        
    }

    function addOption(arr, lbl, val){
        if (val){
            arr.push({label: lbl, value:val});
        } else {
            arr.push({label: lbl, value:lbl});
        }
    }
