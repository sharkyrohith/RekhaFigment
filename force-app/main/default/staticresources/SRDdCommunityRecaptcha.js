var sbInterId,submitbutton;
if ((window.location.href.indexOf('contactsupport') != -1) ||
    (window.location.href.indexOf('healthandsafety') != -1) || 
   	(window.location.href.indexOf('emailsupport-staging') != -1) ||
   	(window.location.href.indexOf('emailsupport') != -1) ){
    sbInterId = setInterval(initsb, 100);
}

function initsb() {
    submitbutton = document.getElementsByClassName("contactSupportButton");
    if (submitbutton.length >0){
        submitbutton[0].disabled = true;
        deInitsb();
    }
};

function deInitsb(){
    clearInterval(sbInterId);
}

var sitekey = '6LeXmLoaAAAAAOZqPKofZJAz-qUeFuJdCkUsmdJp';
    if (window.location.href.indexOf('trycaviar') != -1){
        sitekey = '6LcimboaAAAAAEttgwlIxFsBEIaPSoQbmKQ8dn1d';
    }

document.addEventListener('grecaptchaExecute', function(e) {
    grecaptcha.execute(sitekey, {action: e.detail.action}).then(function(token) {
        document.dispatchEvent(new CustomEvent('grecaptchaVerified', {'detail': {response: token, action:e.detail.action}}));
    });
}); 

