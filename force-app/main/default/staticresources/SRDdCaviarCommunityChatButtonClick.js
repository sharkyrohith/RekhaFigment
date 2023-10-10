var interChatId,chatTile,chatBtn;
if (window.location.href.indexOf('contactsupport') != -1){
    interChatId = setInterval(initChatBtn, 100);
}

function initChatBtn() {
    chatBtn = document.getElementsByClassName("embeddedServiceHelpButton")[0];
    chatTile = document.getElementById("ddChat");
    if (chatBtn != null && chatTile != null){
        deInitChatBtn();
        chatTile = document.getElementById("ddChat");
        chatTile.onclick = chatBtnClick;
    }
}

function deInitChatBtn(){
    clearInterval(interChatId);
}

function chatBtnClick(){
    chatBtn.firstChild.click();
}