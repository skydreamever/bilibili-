$('object').attr('type','application/x-typcn-flashblock');
$('.close-btn-wrp').parent().remove();$('.float-pmt').remove();
$(".i-link[href='http://app.bilibili.com']").html('检查更新').attr('href','javascript:window.external.checkForUpdates()');

if(window.location.href.indexOf("av") > 1 || window.location.href.indexOf("live") > 1){
    var fv=$("param[name='flashvars']").val();
    if(!fv){
        fv=$('#bofqiiframe').attr('src');
    }
    if(!fv){
        fv=$('.player').attr('src');
    }
    if(!fv){
        fv=$('embed').attr('flashvars');
    }
    if(!fv){
        fv = 'cid=' + ROOMID;
    }
    var re = /cid=(\d+)&/;
    var m = re.exec(fv);
    var TYPCN_PLAYER_CID = m[1];
    
    if(!$('.i_face').attr('src')){
        $('.login').css('width',200).children('a').html('点击登陆客户端以便发送弹幕');
    }
    
    if(TYPCN_PLAYER_CID){
        if(window.location.origin == 'http://live.bilibili.com'){
            if(ROOMID > 0){
                window.external.playVideoByCID(ROOMID.toString());
            }
            
        }else{
            $('#bofqi').html('<div class="TYPCN_PLAYER_INJECT_PAGE"><div class="player-placeholder"><div class="btn-wrapper n2"><div class="player-placeholder-head">请选择操作</div><div class="src-btn"><a href="javascript:window.external.playVideoByCID(TYPCN_PLAYER_CID)">播放</a></div><div class="src-btn"><a href="javascript:window.external.downloadVideoByCID(TYPCN_PLAYER_CID)">下载</a></div></div></div></div>');
        }
        
    }else{

    }
    
  }