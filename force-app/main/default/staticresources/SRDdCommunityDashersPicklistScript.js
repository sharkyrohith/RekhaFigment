    
    var interId,category,subcategory;
    if (window.location.href.indexOf('contactsupport') != -1){
        interId = setInterval(init, 100);
    }

    function init() {
        category = document.getElementById("communities_dependent_dx_Category__c");
        if (category != null){
            debugger;
            deInit();
            category.onchange = catChange;
            subcategory = document.getElementById("communities_dx_Subcategory__c");
            subcategory.options = [];
            subcategory.disabled = true;
        }
    };
    
    function deInit(){
        clearInterval(interId);
    }
    
    function catChange(){
        var subcatopts = [{label:"-None-", value:"", selected:true}];
        subcategory.options = [];
        var lang = findGetParameter("language");
        if (lang == 'en_US' || lang == 'en_AU'){
            // english
            if (category.value == "Account"){
                addOption(subcatopts,"Activation status");
                addOption(subcatopts,"Add new vehicle");
                addOption(subcatopts,"Forgot password");
                addOption(subcatopts,"Password Assistance");
                addOption(subcatopts,"Ratings");
                addOption(subcatopts,"Scheduling a dash");
                addOption(subcatopts,"Other");
            } else if (category.value == "Sign-up and Orientation"){
                addOption(subcatopts,"Activation Kit");
                addOption(subcatopts,"Background check");
                addOption(subcatopts,"Orientation");
                addOption(subcatopts,"Sign-up status");
                addOption(subcatopts,"Other");
            } else if (category.value == "Payments"){
                addOption(subcatopts,"Covid-19 Financial Assistance");
                addOption(subcatopts,"Fast Pay");
                addOption(subcatopts,"Missing weekly payment");
                addOption(subcatopts,"Order pay-out-of pocket reimbursement");
                addOption(subcatopts,"Pay Incentives");
                addOption(subcatopts,"Referrals");
                addOption(subcatopts,"Other");
            } else if (category.value == "Troubleshooting"){
                addOption(subcatopts,"Dasher App: iOS");
                addOption(subcatopts,"Dasher App: Android");
                addOption(subcatopts,"Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"On-Time Pay Incentive");
                addOption(subcatopts,"Preassignment");
                addOption(subcatopts,"Other");
            } else if (category.value == "Dasher Red Card"){
                addOption(subcatopts,"Other");
            } else if (category.value == "Order Support"){
                addOption(subcatopts,"Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                addOption(subcatopts,"Telehealth for Dashers and Couriers");
                addOption(subcatopts,"Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Report an accident, safety, or legal concern");
                addOption(subcatopts,"Other");
            }
        } else if (lang == 'fr_CA'){
            // French Canadian
            if (category.value == "Account"){
                addOption(subcatopts,"Ajouter un nouveau v\u00E9hicule","Add new vehicle");
                addOption(subcatopts,"Assistance mot de passe","Password Assistance");
                addOption(subcatopts,"\u00E9valuation","Ratings");
                addOption(subcatopts,"Mot de passe oubli\u00E9","Forgot password");
                addOption(subcatopts,"Planifier un tiret","Scheduling a dash");
                addOption(subcatopts,"Statut d'activation","Activation status");
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Sign-up and Orientation"){
                addOption(subcatopts,"Kit d'activation","Activation Kit");
                addOption(subcatopts,"Orientation","Orientation");
                addOption(subcatopts,"Statut d'inscription","Sign-up status");
                addOption(subcatopts,"V\u00E9rification des ant\u00E9c\u00E9dents","Background check");
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Payments"){
                addOption(subcatopts,"Fast Pay","Fast Pay");
                addOption(subcatopts,"Incitatifs salariaux","Pay Incentives");
                addOption(subcatopts,"Les r\u00E9f\u00E9rences","Referrals");
                addOption(subcatopts,"Paiement hebdomadaire manquant","Missing weekly payment");
                addOption(subcatopts,"Remboursement \u00E0 la commande","Order pay-out-of pocket reimbursement");
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Troubleshooting"){
                addOption(subcatopts,"Dasher App: iOS","Dasher App: iOS");
                addOption(subcatopts,"Dasher App: Android","Dasher App: Android");
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"Incitatif salarial ponctuel","On-Time Pay Incentive");
                addOption(subcatopts,"Pr\u00E9-affectation","Preassignment");
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Dasher Red Card"){
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Order Support"){
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                    addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Signaler un accident, un probl\u00E8me de s\u00E9curit\u00E9 ou un probl\u00E8me juridique","Report an accident, safety, or legal concern");
                addOption(subcatopts,"Autre","Other");
            }
             } else if (lang == 'es'){
            // Spanish
            if (category.value == "Account"){
                addOption(subcatopts,"Agregar veh\u00EDculo nuevo","Add new vehicle");
                addOption(subcatopts,"Asistencia con contrase\u00F1a","Password Assistance");
                addOption(subcatopts,"C\u00F3mo fijar el horario de un Dash","Scheduling a dash");
                addOption(subcatopts,"Estado de la activaci\u00F3n","Activation status");
                addOption(subcatopts,"\u00BFOlvidaste tu contrase\u00F1a?","Forgot password");
                addOption(subcatopts,"Valuaciones","Ratings");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Sign-up and Orientation"){
                addOption(subcatopts,"Estado del registro","Sign-up status");
                addOption(subcatopts,"Kit de activaci\u00F3n","Activation Kit");
                addOption(subcatopts,"Orientaci\u00F3n","Orientation");
                addOption(subcatopts,"Verificaci\u00F3n de antecedentes","Background check");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Payments"){
                addOption(subcatopts,"Falta el pago semanal","Missing weekly payment");
                addOption(subcatopts,"Incentivos de pago","Pay Incentives");
                addOption(subcatopts,"Pago r\u00E1pido","Fast Pay");
                addOption(subcatopts,"Reembolso del pago del bolsillo de la orden","Order pay-out-of pocket reimbursement");
                addOption(subcatopts,"Referencias","Referrals");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Troubleshooting"){
                addOption(subcatopts,"Aplicaci\u00F3n Dasher: iOS","Dasher App: iOS");
                addOption(subcatopts,"Aplicaci\u00F3n Dasher: Android","Dasher App: Android");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"Incentivo de pago a tiempo","On-Time Pay Incentive");
                addOption(subcatopts,"Preasignaci\u00F3n","Preassignment");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Dasher Red Card"){
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Order Support"){
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                	addOption(subcatopts,"Telesalud para Dashers y Couriers","Telehealth for Dashers and Couriers");
                    addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Informar un accidente, una inquietud de seguridad o legal","Report an accident, safety, or legal concern");
                addOption(subcatopts,"Otro","Other");
            }
        } else {
            // common options
           
        }


        subcategory.options=subcatopts;
        //subcategory.options[0].selected=true;
        subcategory.value = "";
        subcategory.focus();
        if (subcatopts.length == 1){
            subcategory.disabled = true;
        } else {
            subcategory.disabled = false;
        }
        
    }

    function addOption(arr, lbl, val){
        if (val){
            arr.push({label: lbl, value:val});
        } else {
            arr.push({label: lbl, value:lbl});
        }
    }

    function findGetParameter(parameterName) {
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
    }