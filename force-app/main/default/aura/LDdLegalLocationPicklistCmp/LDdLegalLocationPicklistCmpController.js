({
    doInit : function(component, event, helper) {
        var countries = component.get("v.countries");
        var countryOptions =  [];
        if (countries.includes("us")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_United_States"), 
                                    value: "us", 
                                    selected:true});
        } 
        
        if (countries.includes("ca")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_Canada"), 
                                    value: "ca", 
                                    selected:false});
        } 
        
        if (countries.includes("au")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_Australia"), 
                                    value: "au", 
                                    selected:false});
        } 
        
        if (countries.includes("mx")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_Mexico"), 
                                    value: "mx", 
                                    selected:false});
        } 
        
        if (countries.includes("jp")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_Japan"), 
                                    value: "jp", 
                                    selected:false});
        }

        if (countries.includes("de")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_Germany"), 
                                    value: "de", 
                                    selected:false});
        }
        if (countries.includes("nz")){
            countryOptions.push({   label: $A.get("$Label.c.DdCommunity_Legal_New_Zealand"), 
                                    value: "nz", 
                                    selected:false});
        }
        component.set("v.countryOptions", countryOptions);
    },
    onCountryChange : function(component, event, helper) {
        var baseURL = component.get("v.BaseURL");
        var commName = component.get("v.CommunityName");
        if (commName == 'helphub'){
            commName = '';
        } else {
            commName += '/';
        }
        var agreeType = component.get("v.AgreementType");
        var selectedLocation = component.get("v.LocationDefault");
        window.location.href = baseURL + commName + 's/' + agreeType + '-' + selectedLocation;
    }
})