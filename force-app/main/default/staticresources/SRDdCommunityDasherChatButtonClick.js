var interChatId,chatTile,chatBtn,chatOnOpen;
if (window.location.href.indexOf('dasher-support') != -1){
    interChatId = setInterval(initChatBtn, 100);
}
if (window.location.href.indexOf('chatonopen=true') != -1){
    chatOnOpen = true;
} else {
    chatOnOpen = false;
}

function initChatBtn() {
    chatBtn = document.getElementsByClassName("embeddedServiceHelpButton")[0];
    chatTile = document.getElementById("ddChat");
    if (chatBtn != null && chatTile != null && (!chatBtn.firstChild.innerText.includes("Offline"))){
        deInitChatBtn();
        chatTile = document.getElementById("ddChat");
        chatTile.onclick = chatBtnClick;
        debugger;
        if (chatOnOpen){
            chatBtnClick();
        }
    }
}

function deInitChatBtn(){
    clearInterval(interChatId);
}

function chatBtnClick(){
    chatBtn = document.getElementsByClassName("embeddedServiceHelpButton")[0];
    if (chatBtn){
        chatBtn.firstChild.click();
    }s
}