    
    var interId,category,subcategory;
    if ((window.location.href.indexOf('contactsupport') != -1) ||
       	(window.location.href.indexOf('caviar-merchant-support-form') != -1)){
        interId = setInterval(init, 100);
    }

    function init() {
        category = document.getElementById("communities_dependent_mx_Category__c");
        if (category != null){
            deInit();
            category.onchange = catChange;
            subcategory = document.getElementById("communities_mx_Subcategory__c");
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
            if (category.value == "Account Support"){
                //addOption(subcatopts,"Address Change");
                addOption(subcatopts,"Close Store");
                addOption(subcatopts,"Grow Your Sales");
                addOption(subcatopts,"Password Assistance");
                addOption(subcatopts,"Payments");
                //addOption(subcatopts,"Store Hours");
                addOption(subcatopts,"Tax");
                addOption(subcatopts,"Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"Other");
            } else if (category.value == "Menu Update"){
                addOption(subcatopts,"Submit a menu update request");
                addOption(subcatopts,"Other");
            } else if (category.value == "Sign-up and Onboarding"){
                addOption(subcatopts,"Activate my store");
                addOption(subcatopts,"Become a DoorDash Partner");
                addOption(subcatopts,"Receiving a tablet");
                addOption(subcatopts,"Other");
            } else if (category.value == "Tablet + Tech Troubleshooting"){
                addOption(subcatopts,"Merchant Portal");
                addOption(subcatopts,"Printers");
                addOption(subcatopts,"Tablets");
                addOption(subcatopts,"Other");
            } else if (category.value == "Feedback"){
                addOption(subcatopts,"Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                addOption(subcatopts,"Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Project DASH");
                addOption(subcatopts,"Report an accident, safety, or legal concern");
                addOption(subcatopts,"Unauthorized Charge");
                addOption(subcatopts,"Other");
            }

        } else if (lang == 'fr_CA'){
            // French Canadian
            if (category.value == "Account Support"){
                addOption(subcatopts,"Assistance mot de passe","Password Assistance");
                //addOption(subcatopts,"Changement d'adresse","Address Change");
                addOption(subcatopts,"D\u00E9veloppez vos ventes","Grow Your Sales");
                addOption(subcatopts,"Fermer le magasin","Close Store");
                //addOption(subcatopts,"Heures d'ouverture","Store Hours");
                addOption(subcatopts,"imp\u00F5t","Tax");
                addOption(subcatopts,"Paiements","Payments");
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Menu Update"){
                addOption(subcatopts,"Soumettre une demande de mise \u00E0 jour de menu","Submit a menu update request");
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Sign-up and Onboarding"){
                addOption(subcatopts,"Activer mon magasin","Activate my store");
                addOption(subcatopts,"Devenir un partenaire DoorDash","Become a DoorDash Partner");
                addOption(subcatopts,"Recevoir une tablette","Receiving a tablet");
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Tablet + Tech Troubleshooting"){
                addOption(subcatopts,"Comprim\u00E9s","Tablets");
                addOption(subcatopts,"Imprimante","Printers");
                addOption(subcatopts,"Portail marchand","Merchant Portal");
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Feedback"){
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                addOption(subcatopts,"Autre","Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Charge non autoris\u00E9e","Unauthorized Charge");
                addOption(subcatopts,"Project DASH","Project DASH");
                addOption(subcatopts,"Signaler un accident, un probl\u00E8me de s\u00E9curit\u00E9 ou un probl\u00E8me juridique","Report an accident, safety, or legal concern");
                addOption(subcatopts,"Autre","Other");
            }
            
            } else if (lang == 'es'){
            // Spanish
            if (category.value == "Account Support"){
                addOption(subcatopts,"Asistencia con contrase\u00F1a","Password Assistance");
                addOption(subcatopts,"Aumenta tus ventas","Grow Your Sales");
                //addOption(subcatopts,"Cambio de direcci\u00F3n","Address Change");
                addOption(subcatopts,"Cerrar tienda","Close Store");
                //addOption(subcatopts,"Horario de la tienda","Store Hours");
                addOption(subcatopts,"Impuestos","Tax");
                addOption(subcatopts,"Pagos","Payments");
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "DoorDash Drive"){
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Menu Update"){
                addOption(subcatopts,"Enviar una solicitud de actualizaci\u00F3n del men\u00FA","Submit a menu update request");
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Sign-up and Onboarding"){
                addOption(subcatopts,"Activar mi tienda","Activate my store");
                addOption(subcatopts,"Convi\u00E9rtete en socio de DoorDash","Become a DoorDash Partner");
                addOption(subcatopts,"Recibir una tableta","Receiving a tablet");
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Tablet + Tech Troubleshooting"){
                addOption(subcatopts,"Impresoras","Printers");
                addOption(subcatopts,"Portal de la tienda","Merchant Portal");
                addOption(subcatopts,"Tabletas","Tablets");
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Feedback"){
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Health, Safety or Legal Concern"){
                addOption(subcatopts,"Otro","Other");
            } else if (category.value == "Other"){
                addOption(subcatopts,"Charge non autoris\u00E9e","Unauthorized Charge");
                addOption(subcatopts,"Inquietud de salud, seguridad o legal","Report an accident, safety, or legal concern");
                addOption(subcatopts,"Project DASH","Project DASH");
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