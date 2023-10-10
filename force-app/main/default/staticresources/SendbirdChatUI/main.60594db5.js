(self.webpackChunk_doordash_app_chat_agent=self.webpackChunk_doordash_app_chat_agent||[]).push([[179],{58596:(e,t,n)=>{"use strict";var r,a,o=n(67294),i=n(73935),c=n(2804),l=n(45861),u=n(16473),s={loading:!1},d=(0,c.cn)({key:"chatInfoState",default:s}),f=(0,c.cn)({key:"chatEndedState",default:s}),y=function(){return(0,c.Zl)(f)},h=(0,c.cn)({key:"quickTextInfoState",default:s}),p=(0,c.cn)({key:"initializedState",default:!1}),m=function(){return(0,c.sJ)(p)};!function(e){e.ChatInfo="chat_info",e.EndChat="end_chat",e.Ping="ping",e.QuickText="quick_text"}(r||(r={})),function(e){e.Error="error",e.Success="success"}(a||(a={}));function g(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}var v=function(e){var t=m();o.useEffect((function(){t&&(console.log("[App] Sending message: ".concat(e.type)),u.sendMessage(e))}),[t])},b=function(){var e,t,n=(e=(0,c.FV)(f),t=2,function(e){if(Array.isArray(e))return e}(e)||function(e,t){if("undefined"!=typeof Symbol&&Symbol.iterator in Object(e)){var n=[],r=!0,a=!1,o=void 0;try{for(var i,c=e[Symbol.iterator]();!(r=(i=c.next()).done)&&(n.push(i.value),!t||n.length!==t);r=!0);}catch(e){a=!0,o=e}finally{try{r||null==c.return||c.return()}finally{if(a)throw o}}return n}}(e,t)||function(e,t){if(e){if("string"==typeof e)return g(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);return"Object"===n&&e.constructor&&(n=e.constructor.name),"Map"===n||"Set"===n?Array.from(e):"Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?g(e,t):void 0}}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()),a=n[0],o=n[1],i={type:r.EndChat};return[function(){o({loading:!0}),u.sendMessage(i)},a]},E=n(76575),k=n(56877),w=n(15517);const C=function(){var e=y();return o.createElement(w.bZ,{dismissText:"Dismiss",onDismiss:function(){return e({loading:!1})},subtitle:"There was an error while trying to end the chat session.",title:"Unable to end chat"})};var S=n(27366),I=n(34144),A=(0,k.Y4)(I.ZP.div.withConfig({displayName:"styles__Wrapper",componentId:"sc-1ctar1i-0"})(["align-items:center;background-color:",";display:flex;height:100vh;justify-content:center;width:100%;"],(function(e){return e.theme.Colors.BackgroundPrimary})));const T=function(){return o.createElement(A,null,o.createElement(S.Z,{color:S.Z.Colors.Dark}))};function _(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}const x=function(){var e,t,n,a,i,l=(a=b(),i=2,function(e){if(Array.isArray(e))return e}(a)||function(e,t){if("undefined"!=typeof Symbol&&Symbol.iterator in Object(e)){var n=[],r=!0,a=!1,o=void 0;try{for(var i,c=e[Symbol.iterator]();!(r=(i=c.next()).done)&&(n.push(i.value),!t||n.length!==t);r=!0);}catch(e){a=!0,o=e}finally{try{r||null==c.return||c.return()}finally{if(a)throw o}}return n}}(a,i)||function(e,t){if(e){if("string"==typeof e)return _(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);return"Object"===n&&e.constructor&&(n=e.constructor.name),"Map"===n||"Set"===n?Array.from(e):"Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?_(e,t):void 0}}(a,i)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()),u=l[0],s=l[1],f=(n={type:r.ChatInfo},v(n),(0,c.sJ)(d)),y=function(){var e={type:r.QuickText};return v(e),(0,c.sJ)(h)}();return f.error?o.createElement("div",null,"Error"):f.loading||!f.data?o.createElement(T,null):o.createElement(o.Fragment,null,o.createElement(E.Z,{accessToken:f.data.sendbirdToken,appId:f.data.sendbirdAppId,channelUrl:f.data.sendbirdChannelUrl,fieldMap:(null===(e=y.data)||void 0===e?void 0:e.fieldMap)||{},header:{iconType:k.JO.Types.ChatConversation,onEndChat:u},onChatResume:function(){return null},quickTextItems:(null===(t=y.data)||void 0===t?void 0:t.items)||[],userId:f.data.sendbirdUserId}),!!s.error&&o.createElement(C,null))},Z=function(){var e,t,n,i,s,f,g,v,b,E;return i=y(),s=(0,c.Zl)(d),f=(0,c.Zl)(p),g=(0,c.Zl)(h),v=function(e){switch(e.status){case a.Success:return{error:null,loading:!1,data:e.data};case a.Error:default:return{error:e.message,loading:!1}}},b=function(e){switch(console.log("[App] Received message: ".concat(e.type," "),e),e.type){case r.ChatInfo:s(v(e.payload));break;case r.EndChat:i(v(e.payload));break;case r.Ping:f(!0);break;case r.QuickText:g(v(e.payload));break;default:console.log("[App]: Unhandled message type")}},E=function(e){console.log("LCC ERROR: ",e)},o.useEffect((function(){return u.addMessageHandler(b),u.addErrorHandler(E),function(){u.removeMessageHandler(b),u.removeErrorHandler(E)}}),[]),e=m(),t=o.useRef(),n=function(){t.current&&window.clearInterval(t.current)},o.useEffect((function(){return t.current=window.setInterval((function(){u.sendMessage({type:r.Ping})}),1e3),function(){return n()}}),[]),o.useEffect((function(){e&&n()}),[e]),o.createElement(l.ZP,null,o.createElement(x,null))};var j=document.querySelector("#root");if(!j)throw new Error("no root element");i.render(o.createElement(c.Wh,null,o.createElement(Z,null)),j)}},0,[[58596,303,606]]]);