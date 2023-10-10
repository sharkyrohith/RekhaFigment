	
	var interId,category,subcategory;
    if (window.location.href.indexOf('contactsupport') != -1){
        interId = setInterval(init, 100);
    }

    function init() {
        category = document.getElementById("comm_dependent_cx_Category__c");
        if (category != null){
            deInit();
            fillCategory();
            category.onchange = catChange;
            subcategory = document.getElementById("communities_cx_Subcategory__c");
            subcategory.options = [];
            subcategory.disabled = true;
        }
    };
    
    function deInit(){
        clearInterval(interId);
    }
 	
	function fillCategory(){
        var catopts = [{label:"-None-", value:"", selected:true}];
        category.options = [];
        var lang = findGetParameter("language");
        if (lang == 'en_US' || lang == 'en_AU'){
            addOption(catopts,"Account Settings");
            addOption(catopts,"Payments");
            addOption(catopts,"App Troubleshooting");
            addOption(catopts,"Post Delivery Support");  
            addOption(catopts,"Health, Safety or Legal Concern (including allergies or allergic reactions)");    
            addOption(catopts,"Other");         
        } else if (lang == 'es'){
            addOption(catopts,"Configuraciones de la cuenta","Account Settings");
            addOption(catopts,"Pagos","Payments");
            addOption(catopts,"Soluci�n de problemas de aplicaciones","App Troubleshooting");
            addOption(catopts,"Soporte post entrega","Post Delivery Support");  
            addOption(catopts,"Salud, seguridad o preocupaci�n legal (incluidas alergias o reacciones al�rgicas)","Health, Safety or Legal Concern (including allergies or allergic reactions)");   
            addOption(catopts,"Otro","Other");          
        } else if (lang == 'fr_CA'){
            addOption(catopts,"Param\u00E8tres du compte","Account Settings");
            addOption(catopts,"Paiements","Payments");
            addOption(catopts,"D\u00E9pannage de l'application","App Troubleshooting");
            addOption(catopts,"Support apr\u00E8s livraison","Post Delivery Support");  
            addOption(catopts,"Pr\u00E9occupations en mati\u00E8re de sant\u00E9, de s\u00E9curit\u00E9 ou juridiques (y compris les allergies ou les r\u00E9actions allergiques)","Health, Safety or Legal Concern (including allergies or allergic reactions)");
            addOption(catopts,"Autre","Other");             
        }
        category.options=catopts;
        category.value = "";
        
    }
   
    function catChange(){
        var subcatopts = [{label:"-None-", value:"", selected:true}];
        subcategory.options = [];
        var lang = findGetParameter("language");
        if (lang == 'en_US' || lang == 'en_AU'){
        	// english
            if (category.value == "Account Settings"){
                addOption(subcatopts,"Deactivate DoorDash Account");
                addOption(subcatopts,"Edit Account Information");
                addOption(subcatopts,"Email/Text Unsubscription Request");   
                addOption(subcatopts,"Issues with 2FA");
                addOption(subcatopts,"Reactivate DoorDash Account");
                addOption(subcatopts,"Password Assistance");   
            } else if (category.value == "Payments"){
                addOption(subcatopts,"Credit and Refund Status");
                addOption(subcatopts,"Order Receipt Request");
                addOption(subcatopts,"Promotions and Discounts Questions");
                addOption(subcatopts,"Referral Credits Questions");
                addOption(subcatopts,"Report Unauthorized Charges");
            } else if (category.value == "App Troubleshooting"){
                addOption(subcatopts,"Issues with DoorDash App: IOS");
                addOption(subcatopts,"Issues with DoorDash App: Android");
                addOption(subcatopts,"Issue with DoorDash.com");
            } else if (category.value == "Order In-Progress Support"){
                addOption(subcatopts,"Cancel an Order");                
                addOption(subcatopts,"Change Delivery Address");
                addOption(subcatopts,"Change Delivery Time");
                addOption(subcatopts,"Delivery and Service Fees Questions");
                addOption(subcatopts,"Order Adjustments Requests");
                addOption(subcatopts,"Order Status");
                addOption(subcatopts,"Special Delivery or Order Instructions");
            } else if (category.value == "Post Delivery Support"){
                addOption(subcatopts,"Adjust Dasher Tip");
                addOption(subcatopts,"Dasher Feedback");
                addOption(subcatopts,"Did Not Receive Order");
                addOption(subcatopts,"Missing or Incorrect Items from Order");
                addOption(subcatopts,"No-Contact Delivery");
                addOption(subcatopts,"Order is late");
                addOption(subcatopts,"Restaurant Feedback");                
			} else if (category.value == "Health, Safety or Legal Concern (including allergies or allergic reactions)"){
              	addOption(subcatopts,"Report an accident, safety, or legal concern");
			} else if (category.value == "Other"){
                addOption(subcatopts,"About DoorDash");
                addOption(subcatopts,"DashPass Questions");
                addOption(subcatopts,"Project DASH");
                //addOption(subcatopts,"Placing an Order");
                addOption(subcatopts,"Restaurant Ratings");
                addOption(subcatopts,"Restaurant Menu Issues");
            }      
        } else if (lang == 'fr_CA'){
            // French Canadian
            if (category.value == "Account Settings"){
                addOption(subcatopts,"Assistance mot de passe","Password Assistance");  
                addOption(subcatopts,"Demande de d\u00E9sabonnement par e-mail / texte","Email/Text Unsubscription Request");   
                addOption(subcatopts,"D\u00E9sactiver le compte DoorDash","Deactivate DoorDash Account");
                addOption(subcatopts,"Modifier les informations du compte","Edit Account Information");
                addOption(subcatopts,"Probl\u00E8mes avec 2FA","Issues with 2FA");
                addOption(subcatopts,"R\u00E9activer le compte DoorDash","Reactivate DoorDash Account");
             } else if (category.value == "Payments"){
                addOption(subcatopts,"Demande de r\u00E9ception de commande","Order Receipt Request");
                addOption(subcatopts,"Questions sur les cr\u00E9dits de recommandation","Referral Credits Questions");
                addOption(subcatopts,"Questions sur les promotions et r\u00E9ductions","Promotions and Discounts Questions");
                addOption(subcatopts,"Signaler des frais non autoris\u00E9s","Report Unauthorized Charges");
                addOption(subcatopts,"Statut de cr\u00E9dit et de remboursement","Credit and Refund Status");
            } else if (category.value == "App Troubleshooting"){
                addOption(subcatopts,"Probl\u00E8mes avec l'application DoorDash: iOS","DoorDash App: Android");
                addOption(subcatopts,"Probl\u00E8mes avec l'application DoorDash: Android","DoorDash App: IOS");
                addOption(subcatopts,"Probl\u00E8me avec DoorDash.com","Issue with DoorDash.com");
            } else if (category.value == "Order In-Progress Support"){
                addOption(subcatopts,"Changer l'adresse de livraison","Change Delivery Address");
                addOption(subcatopts,"Demandes d'ajustement de commande","Order Adjustments Requests");
                addOption(subcatopts,"Instructions de livraison ou de commande sp\u00E9ciales","Special Delivery or Order Instructions");
                addOption(subcatopts,"Modifier le d\u00E9lai de livraison","Change Delivery Time");
                addOption(subcatopts,"Questions sur les frais de livraison et de service","Delivery and Service Fees Questions");
                addOption(subcatopts,"Questions sur les frais de livraison et de service","Cancel an Order");   
                addOption(subcatopts,"Statut de la commande","Order Status");
            } else if (category.value == "Post Delivery Support"){
                addOption(subcatopts,"Ajuster le bout droit","Adjust Dasher Tip");
                addOption(subcatopts,"Articles manquants ou incorrects de la commande","Missing or Incorrect Items from Order");
                addOption(subcatopts,"Commentaires du restaurant","Restaurant Feedback");    
                addOption(subcatopts,"Dasher Commentaires","Dasher Feedback");
                addOption(subcatopts,"La commande est en retard","Order is late");
                addOption(subcatopts,"Livraison sans contact","No-Contact Delivery");
                addOption(subcatopts,"N'a pas re\u00E7u de commande","Did Not Receive Order");
			} else if (category.value == "Health, Safety or Legal Concern (including allergies or allergic reactions)"){
              	addOption(subcatopts,"Signaler un accident, un probl\u00E8me de s\u00E9curit\u00E9 ou un probl\u00E8me juridique","Report an accident, safety, or legal concern");
			} else if (category.value == "Other"){
                addOption(subcatopts,"\u00E9valuation du restaurant","Restaurant Ratings");
                addOption(subcatopts,"\u00C0 propos de DoorDash","About DoorDash");
                addOption(subcatopts,"Projet DASH","Project DASH");
                //addOption(subcatopts,"Passer une commande","Placing an Order");
                addOption(subcatopts,"Probl\u00E8mes de menu de restaurant","Restaurant Menu Issues");
                addOption(subcatopts,"Questions DashPass","DashPass Questions");

            }
        }  else if (lang == 'es'){
            // Spanish
         if (category.value == "Account Settings"){
                addOption(subcatopts,"Asistencia con contrase\u00F1a","Password Assistance");   
                addOption(subcatopts,"Editar informaci\u00F3n de la cuenta","Edit Account Information");
                addOption(subcatopts,"Desactivar cuenta DoorDash","Deactivate DoorDash Account");
                addOption(subcatopts,"Problemas con 2FA","Issues with 2FA");
                addOption(subcatopts,"Reactivar la cuenta de DoorDash","Reactivate DoorDash Account");
                addOption(subcatopts,"Solicitud de baja de correo electr\u00F3nico / texto","Email/Text Unsubscription Request");  
             } else if (category.value == "Payments"){
                addOption(subcatopts,"Informar cargos no autorizados","Report Unauthorized Charges");
                addOption(subcatopts,"Estado de cr\u00E9dito y reembolso","Credit and Refund Status");
                addOption(subcatopts,"Preguntas sobre promociones y descuentos","Promotions and Discounts Questions");
                addOption(subcatopts,"Referral Credits Questions","Referral Credits Questions");
                addOption(subcatopts,"Solicitud de recibo de pedido","Order Receipt Request");
            } else if (category.value == "App Troubleshooting"){
                addOption(subcatopts,"Problemas con la aplicaci\u00F3n DoorDash: iOS","DoorDash App: Android");
                addOption(subcatopts,"Problemas con la aplicaci\u00F3n DoorDash: Android","DoorDash App: IOS");
                addOption(subcatopts,"Problema con DoorDash.com","Issue with DoorDash.com");
            } else if (category.value == "Order In-Progress Support"){
                addOption(subcatopts,"Cambiar direcci\u00F3n de entrega","Change Delivery Address");
                addOption(subcatopts,"Cambiar tiempo de entrega","Change Delivery Time");
                addOption(subcatopts,"Cancelar un pedido","Cancel an Order");                
                addOption(subcatopts,"Entrega especial o instrucciones de pedido","Special Delivery or Order Instructions");
                addOption(subcatopts,"Estado del pedido","Order Status");
                addOption(subcatopts,"Preguntas sobre tarifas de entrega y servicio","Delivery and Service Fees Questions");
                addOption(subcatopts,"Solicitudes de ajustes de pedidos","Order Adjustments Requests");
            } else if (category.value == "Post Delivery Support"){
                addOption(subcatopts,"Art\u00EDculos faltantes o incorrectos del pedido","Missing or Incorrect Items from Order");
                addOption(subcatopts,"Ajuste la punta de Dasher","Adjust Dasher Tip");
                addOption(subcatopts,"Comentarios de Dasher","Dasher Feedback");
                addOption(subcatopts,"Comentarios del restaurante","Restaurant Feedback"); 
                addOption(subcatopts,"El pedido llega tarde","Order is late");
                addOption(subcatopts,"Entrega sin contacto","No-Contact Delivery");
                addOption(subcatopts,"No recib\u00ED la orden","Did Not Receive Order"); 
			} else if (category.value == "Health, Safety or Legal Concern (including allergies or allergic reactions)"){
              	addOption(subcatopts,"Informar un accidente, seguridad o inquietud legal","Report an accident, safety, or legal concern");
			} else if (category.value == "Other"){
                addOption(subcatopts,"Clasificaciones de restaurantes","Restaurant Ratings");
                //addOption(subcatopts,"Ordenando","Placing an Order");
                addOption(subcatopts,"Proyecto DASH","Project DASH");
                addOption(subcatopts,"Preguntas DashPass","DashPass Questions");
                addOption(subcatopts,"Problemas del men\u00FA del restaurante","Restaurant Menu Issues");
                addOption(subcatopts,"Sobre DoorDash","About DoorDash");
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