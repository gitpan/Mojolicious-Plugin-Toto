package Toto;
use Mojolicious::Lite;
use Mojo::ByteStream qw/b/;
use File::Basename qw/dirname/;
use File::Spec;

use Toto::Model;

get '/' => { layout => "toto", controller => '', action => '' } => 'toto';
get '/jq.css'        => sub { shift->render_static("jq.css")   };
get '/toto.css'      => sub { shift->render_static("toto.css") };

get '/toto/images/:which.png' =>
    [ which =>
    qr[ui-bg_(?:highlight-)?(?:flat|glass|soft)_(?:\d+)_(?:\w{6})_(?:\d+)x(?:\d+)] =>
    ] => sub {
    my $c = shift;
    my $which = $c->stash("which").".png";
    $c->render_static( $which );
};

1;
__DATA__
@@ layouts/toto.html.ep
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN">
<html>
<head>
<title><%= title %></title>
%= base_tag
%= stylesheet '/toto.css';
%= stylesheet '/jq.css';
%= javascript '/js/jquery.js';
</head>
<body>
<div class="ui-tabs ui-widget ui-widget-content ui-corner-all container">
    <ul class="ui-widget tabs">
% for my $c (controllers) {
        <li <%== $c eq $controller ? q[ class="ui-state-active"] : "" =%>>
            <%= link_to $c => begin =%><%= $c =%><%= end =%>
        </li>
% }
    </ul>
    <div class="tab_container">
         <div class="toptab_container ui-tabs ui-widget ui-widget-content ui-corner-all">
% if (stash 'key') {
%= include 'top_tabs_single';
% } else {
%= include 'top_tabs_plural';
% }
         <div class="page_content">
         <%= content =%>
         </div>
         </div>
    </div>
</div>
<script>
//Default Action
//$("ul.tabs li.active").show(); //Activate active tab
$(".toptab_container").show(); //Show tab content
//On Click Event
$("ul.tabs li").click(function() {
    $("ul.tabs li").removeClass("active"); //Remove any "active" class
    $("ul.tabs li").removeClass("ui-state-active"); //Remove any "active" class
    $(this).addClass("active"); //Add "active" class to selected tab
    $(this).addClass("ui-state-active"); //Add "active" class to selected tab
    $(".toptab_container").hide(); //Hide all tab content
    var activeTab = $(this).find("a").attr("href"); //Find the active tab + content
    $(activeTab).fadeIn(); //Fade in the active content
    return false;
});
//$(".toptab_container").tabs();
$(".toptab_container ul li").addClass("ui-state-default ui-corner-top");
$(".toptab_container ul li").click(function() {
    $("ul.toptabs li").removeClass("ui-state-active");
    $("ul.toptabs li").removeClass("active");
    $(".page_content").hide();
    $(this).addClass("ui-state-active");
});

</script>

% if (toto_config->{themeswitcher}) {
% my $theme = $self->cookie('toto-theme') || "Smoothness";
% $theme = b($theme)->url_unescape;
<script>
$(document).ready(function () {
    $.cookie('jquery-ui-theme', "<%= $theme %>");
    $('#ThemeRoller').themeswitcher({
        loadTheme : "<%= $theme %>",
        onSelect : function() {
         $.cookie('toto-theme', $.cookie("jquery-ui-theme"), { path : '/' });
         }
        });
});
</script>
<script type="text/javascript"
  src="http://jqueryui.com/themeroller/themeswitchertool/">
</script>
<div id="ThemeRoller" style='position:fixed; top:2px; right:5px;'></div>
% }
</html>

@@ top_tabs_plural.html.ep
<ul class="toptabs ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
% for my $a (actions) {
    <li <%== $a eq $action ? q[ class="active ui-state-active"] : '' %>>
        <%= link_to "$controller/$a" => begin =%>
            <%= $a =%>
        <%= end =%>
    </li>
% }
</ul>

@@ top_tabs_single.html.ep
<h2><%= $controller %> <%= $instance->key %></h2>
<ul class="toptabs ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all">
% for my $a (actions) {
    <li <%== $a eq $action ? q[ class="active ui-state-active"] : '' %>>
        <%= link_to "$controller/$a/".$instance->key => begin =%>
            <%= $a =%>
        <%= end =%>
    </li>
% }
</ul>


@@ single.html.ep
This is the page for <%= $action %> for
<%= $controller %> <%= $key %>.
<pre class="ui-widget code">
get '/<%= $controller %>/<%= $action %>/*key' => sub {
% if ($self->app->routes->namespace) {
    # or define <%= $self->app->routes->namespace %>::<%= b($controller)->camelize %>::<%= $action %>()
% }
    ...
} => '<%= $controller %>/<%= $action %>';

# templates/<%= $controller %>/<%= $action %>.html.ep
This is the page for
&lt%= $action %&gt; for &lt;%= $controller %&gt;
&lt;%= $<%= $controller %>-&gt;key %&gt;
</pre>

@@ plural.html.ep
% use Mojo::ByteStream qw/b/;
<pre class="ui-widget code">
get '/<%= $controller %>/<%= $action %>' => sub {
% if ($self->app->routes->namespace) {
    # or define <%= $self->app->routes->namespace %>::<%= b($controller)->camelize %>::<%= $action %>()
% }
    ...
} => '<%= $controller %>/<%= $action %>';

# templates/<%= $controller %>/<%= $action %>.html.ep
<%= '%' %> for (1..10) {
<%= '%' %>= link_to "<%= $controller %>/default/$_" => begin
<%= $controller %> &lt;%= $_ %&gt;&lt;br&gt;
<%= '%' %>= end
<%= '%' %> }
</pre>
% for (1..10) {
%= link_to "$controller/default/$_" => begin
<%= $controller %> <%= $_ %><br>
%= end
% }

@@ toto.html.ep
% use File::Basename qw/basename/;
<center>
<br>
Welcome, to <%= basename($ENV{MOJO_EXE}) %><br>
Please choose a menu item.
</center>

@@ toto.css
html,body {
    height:95%;
    border:none;
    }
body {
    background: #f0f0f0;
    margin: 0;
    padding: 0;
    font: Verdana, Arial, Helvetica, sans-serif;
    color: #444;
}
.container {width: 90% margin: 10px auto; height:95%;}
ul.tabs {
    margin: 0;
    padding: 0;
    float: left;
    list-style: none;
    height: 32px;
    width: 15%;
}
ul.tabs li {
    float: top;
    margin: 0;
    padding: 0;
    height: 31px;
    line-height: 31px;
    border-left: none;
    margin-bottom: 0px;
    overflow: hidden;
    position: relative;
}
ul.tabs li a {
    text-decoration: none;
    display: block;
    font-size: 1.2em;
    padding: 0 20px;
    outline: none;
}
ul.tabs li a:hover {
}   
html ul.tabs li.active, html ul.tabs li.active a:hover  {
}
.tab_container {
    border: 1px solid #999;
    background: #fff;
    height:95%;
    margin-left:15%;
    -moz-border-radius-bottomright: 5px;
    -khtml-border-radius-bottomright: 5px;
    -webkit-border-bottom-right-radius: 5px;
    -moz-border-radius-bottomleft: 5px;
    -khtml-border-radius-bottomleft: 5px;
    -webkit-border-bottom-left-radius: 5px;
}
.toptab_container {
    height: 100%;
    font-size: 1.2em;
}
.toptab_container h2 {
    text-align:center;
    font-weight: normal;
    font-size: 1.8em;
    height:5%;
}
.page_content {
    height:95%;
}
pre.code {
    float:right;
    margin-right:20px;
    padding:5px;
    border:1px grey dashed;
    font-family:monospace;
    }

@@ jq.css
/*
* jQuery UI CSS Framework
* Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
* Dual licensed under the MIT (MIT-LICENSE.txt) and GPL (GPL-LICENSE.txt) licenses.
*/

/* Layout helpers
----------------------------------*/
.ui-helper-hidden { display: none; }
.ui-helper-hidden-accessible { position: absolute; left: -99999999px; }
.ui-helper-reset { margin: 0; padding: 0; border: 0; outline: 0; line-height: 1.3; text-decoration: none; font-size: 100%; list-style: none; }
.ui-helper-clearfix:after { content: "."; display: block; height: 0; clear: both; visibility: hidden; }
.ui-helper-clearfix { display: inline-block; }
/* required comment for clearfix to work in Opera \*/
* html .ui-helper-clearfix { height:1%; }
.ui-helper-clearfix { display:block; }
/* end clearfix */
.ui-helper-zfix { width: 100%; height: 100%; top: 0; left: 0; position: absolute; opacity: 0; filter:Alpha(Opacity=0); }


/* Interaction Cues
----------------------------------*/
.ui-state-disabled { cursor: default !important; }


/* Misc visuals
----------------------------------*/

/* Overlays */
.ui-widget-overlay { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }

/*
* jQuery UI CSS Framework
* Copyright (c) 2009 AUTHORS.txt (http://jqueryui.com/about)
* Dual licensed under the MIT (MIT-LICENSE.txt) and GPL (GPL-LICENSE.txt) licenses.
* To view and modify this theme, visit http://jqueryui.com/themeroller/?ffDefault=Verdana,Arial,sans-serif&fwDefault=normal&fsDefault=1.1em&cornerRadius=4px&bgColorHeader=cccccc&bgTextureHeader=03_highlight_soft.png&bgImgOpacityHeader=75&borderColorHeader=aaaaaa&fcHeader=222222&iconColorHeader=222222&bgColorContent=ffffff&bgTextureContent=01_flat.png&bgImgOpacityContent=75&borderColorContent=aaaaaa&fcContent=222222&iconColorContent=222222&bgColorDefault=e6e6e6&bgTextureDefault=02_glass.png&bgImgOpacityDefault=75&borderColorDefault=d3d3d3&fcDefault=555555&iconColorDefault=888888&bgColorHover=dadada&bgTextureHover=02_glass.png&bgImgOpacityHover=75&borderColorHover=999999&fcHover=212121&iconColorHover=454545&bgColorActive=ffffff&bgTextureActive=02_glass.png&bgImgOpacityActive=65&borderColorActive=aaaaaa&fcActive=212121&iconColorActive=454545&bgColorHighlight=fbf9ee&bgTextureHighlight=02_glass.png&bgImgOpacityHighlight=55&borderColorHighlight=fcefa1&fcHighlight=363636&iconColorHighlight=2e83ff&bgColorError=fef1ec&bgTextureError=02_glass.png&bgImgOpacityError=95&borderColorError=cd0a0a&fcError=cd0a0a&iconColorError=cd0a0a&bgColorOverlay=aaaaaa&bgTextureOverlay=01_flat.png&bgImgOpacityOverlay=0&opacityOverlay=30&bgColorShadow=aaaaaa&bgTextureShadow=01_flat.png&bgImgOpacityShadow=0&opacityShadow=30&thicknessShadow=8px&offsetTopShadow=-8px&offsetLeftShadow=-8px&cornerRadiusShadow=8px
*/


/* Component containers
----------------------------------*/
.ui-widget { font-family: Verdana,Arial,sans-serif; font-size: 1.1em; }
.ui-widget .ui-widget { font-size: 1em; }
.ui-widget input, .ui-widget select, .ui-widget textarea, .ui-widget button { font-family: Verdana,Arial,sans-serif; font-size: 1em; }
.ui-widget-content { border: 1px solid #aaaaaa; background: #ffffff url(/toto/images/ui-bg_flat_75_ffffff_40x100.png) 50% 50% repeat-x; color: #222222; }
.ui-widget-content a { color: #222222; }
.ui-widget-header { border: 1px solid #aaaaaa; background: #cccccc url(/toto/images/ui-bg_highlight-soft_75_cccccc_1x100.png) 50% 50% repeat-x; color: #222222; font-weight: bold; }
.ui-widget-header a { color: #222222; }

/* Interaction states
----------------------------------*/
.ui-state-default, .ui-widget-content .ui-state-default { border: 1px solid #d3d3d3; background: #e6e6e6 url(/toto/images/ui-bg_glass_75_e6e6e6_1x400.png) 50% 50% repeat-x; font-weight: normal; color: #555555; outline: none; }
.ui-state-default a, .ui-state-default a:link, .ui-state-default a:visited { color: #555555; text-decoration: none; outline: none; }
.ui-state-hover, .ui-widget-content .ui-state-hover, .ui-state-focus, .ui-widget-content .ui-state-focus { border: 1px solid #999999; background: #dadada url(/toto/images/ui-bg_glass_75_dadada_1x400.png) 50% 50% repeat-x; font-weight: normal; color: #212121; outline: none; }
.ui-state-hover a, .ui-state-hover a:hover { color: #212121; text-decoration: none; outline: none; }
.ui-state-active, .ui-widget-content .ui-state-active { border: 1px solid #aaaaaa; background: #ffffff url(/toto/images/ui-bg_glass_65_ffffff_1x400.png) 50% 50% repeat-x; font-weight: normal; color: #212121; outline: none; }
.ui-state-active a, .ui-state-active a:link, .ui-state-active a:visited { color: #212121; outline: none; text-decoration: none; }

/* Interaction Cues
----------------------------------*/
.ui-state-highlight, .ui-widget-content .ui-state-highlight {border: 1px solid #fcefa1; background: #fbf9ee url(/toto/images/ui-bg_glass_55_fbf9ee_1x400.png) 50% 50% repeat-x; color: #363636; }
.ui-state-highlight a, .ui-widget-content .ui-state-highlight a { color: #363636; }
.ui-state-error, .ui-widget-content .ui-state-error {border: 1px solid #cd0a0a; background: #fef1ec url(/toto/images/ui-bg_glass_95_fef1ec_1x400.png) 50% 50% repeat-x; color: #cd0a0a; }
.ui-state-error a, .ui-widget-content .ui-state-error a { color: #cd0a0a; }
.ui-state-error-text, .ui-widget-content .ui-state-error-text { color: #cd0a0a; }
.ui-state-disabled, .ui-widget-content .ui-state-disabled { opacity: .35; filter:Alpha(Opacity=35); background-image: none; }
.ui-priority-primary, .ui-widget-content .ui-priority-primary { font-weight: bold; }
.ui-priority-secondary, .ui-widget-content .ui-priority-secondary { opacity: .7; filter:Alpha(Opacity=70); font-weight: normal; }

/* Misc visuals
----------------------------------*/

/* Corner radius */
.ui-corner-tl { -moz-border-radius-topleft: 4px; -webkit-border-top-left-radius: 4px; }
.ui-corner-tr { -moz-border-radius-topright: 4px; -webkit-border-top-right-radius: 4px; }
.ui-corner-bl { -moz-border-radius-bottomleft: 4px; -webkit-border-bottom-left-radius: 4px; }
.ui-corner-br { -moz-border-radius-bottomright: 4px; -webkit-border-bottom-right-radius: 4px; }
.ui-corner-top { -moz-border-radius-topleft: 4px; -webkit-border-top-left-radius: 4px; -moz-border-radius-topright: 4px; -webkit-border-top-right-radius: 4px; }
.ui-corner-bottom { -moz-border-radius-bottomleft: 4px; -webkit-border-bottom-left-radius: 4px; -moz-border-radius-bottomright: 4px; -webkit-border-bottom-right-radius: 4px; }
.ui-corner-right {  -moz-border-radius-topright: 4px; -webkit-border-top-right-radius: 4px; -moz-border-radius-bottomright: 4px; -webkit-border-bottom-right-radius: 4px; }
.ui-corner-left { -moz-border-radius-topleft: 4px; -webkit-border-top-left-radius: 4px; -moz-border-radius-bottomleft: 4px; -webkit-border-bottom-left-radius: 4px; }
.ui-corner-all { -moz-border-radius: 4px; -webkit-border-radius: 4px; }

/* Overlays */
.ui-widget-overlay { background: #aaaaaa url(/toto/images/ui-bg_flat_0_aaaaaa_40x100.png) 50% 50% repeat-x; opacity: .30;filter:Alpha(Opacity=30); }
.ui-widget-shadow { margin: -8px 0 0 -8px; padding: 8px; background: #aaaaaa url(/toto/images/ui-bg_flat_0_aaaaaa_40x100.png) 50% 50% repeat-x; opacity: .30;filter:Alpha(Opacity=30); -moz-border-radius: 8px; -webkit-border-radius: 8px; }


/* Tabs
----------------------------------*/
.ui-tabs { padding: .2em; zoom: 1; }
.ui-tabs .ui-tabs-nav { list-style: none; position: relative; padding: .2em .2em 0; }
.ui-tabs .ui-tabs-nav li { position: relative; float: left; border-bottom-width: 0 !important; margin: 0 .2em -1px 0; padding: 0; }
.ui-tabs .ui-tabs-nav li a { float: left; text-decoration: none; padding: .5em 1em; }
.ui-tabs .ui-tabs-nav li.ui-tabs-selected { padding-bottom: 1px; border-bottom-width: 0; }
.ui-tabs .ui-tabs-nav li.ui-tabs-selected a, .ui-tabs .ui-tabs-nav li.ui-state-disabled a, .ui-tabs .ui-tabs-nav li.ui-state-processing a { cursor: text; }
.ui-tabs .ui-tabs-nav li a, .ui-tabs.ui-tabs-collapsible .ui-tabs-nav li.ui-tabs-selected a { cursor: pointer; } /* first selector in group seems obsolete, but required to overcome bug in Opera applying cursor: text overall if defined elsewhere... */
.ui-tabs .ui-tabs-panel { padding: 1em 1.4em; display: block; border-width: 0; background: none; }
.ui-tabs .ui-tabs-hide { display: none !important; }

@@ ui-bg_flat_75_ffffff_40x100.png (base64)
iVBORw0KGgoAAAANSUhEUgAAACgAAABkCAYAAAD0ZHJ6AAAAeUlEQVRoge3OMQHAIBAAsVL/nh8J
DDfAkCjImpn5HvbfDpwIVoKVYCVYCVaClWAlWAlWgpVgJVgJVoKVYCVYCVaClWAlWAlWgpVgJVgJ
VoKVYCVYCVaClWAlWAlWgpVgJVgJVoKVYCVYCVaClWAlWAlWgpVgJVgJVhtqiwTEKTLXTgAAAABJ
RU5ErkJggg==

@@ ui-bg_glass_65_ffffff_1x400.png (base64)
iVBORw0KGgoAAAANSUhEUgAAAAEAAAGQCAYAAABvWArbAAAAMElEQVQ4je3LIQ4AIBTD0O3f/8wr
FgmKhMy8pKJKwkhSKeVbbGuAPU9f4PIopTxgAeS0DRtI4yK0AAAAAElFTkSuQmCC

@@ ui-bg_glass_75_e6e6e6_1x400.png (base64)
iVBORw0KGgoAAAANSUhEUgAAAAEAAAGQCAYAAABvWArbAAAANUlEQVQ4je3LMQoAIBADwb38/6t5
wFXaWAiCtUiaYZvF9hBACOFbuntVVe11B0CSjjeE8BwThQIJ8dhEl0YAAAAASUVORK5CYII=

@@ ui-bg_highlight-soft_75_cccccc_1x100.png (base64)
iVBORw0KGgoAAAANSUhEUgAAAAEAAABkCAYAAABHLFpgAAAALElEQVQYlWN49OjRfyYGBgaGIUT8
//8fSqBx0Yh///4RL8vAwAAVQ2MNOwIAl6g6KkOJwk8AAAAASUVORK5CYII=

