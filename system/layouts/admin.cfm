<cfscript>
	body             = renderView();
	navbar           = renderView( 'admin/layout/navbar' );
	siteAlerts       = renderViewlet( 'admin.layout.siteAlerts' );
	breadcrumbs      = renderView( 'admin/layout/breadcrumbs' );
	sideBarNav       = renderView( 'admin/layout/sideBarNavigation' );
	notifications    = renderView( 'admin/general/notifications' );
	footer           = renderViewlet( 'admin.general.footer' );

	currentHandler = event.getCurrentHandler();
	currentAction  = event.getCurrentAction();

	event.include( "/css/admin/core/" );
	event.include( "/css/admin/specific/#currentHandler#/", false );
	event.include( "/css/admin/specific/#currentHandler#/#currentAction#/", false );
	event.include( "/js/admin/presidecore/" );
	event.include( "/js/admin/specific/#currentHandler#/", false );
	event.include( "/js/admin/specific/#currentHandler#/#currentAction#/", false );

	event.include( "i18n-resource-bundle" );

	if ( hasCmsPermission( "devtools.console" ) ) {
		event.include( "/js/admin/devtools/" )
		     .include( "/css/admin/devtools/" )
		     .includeData( { devConsoleToggleKeyCode=getSetting( "devConsoleToggleKeyCode" ) } );
	}

	ckEditorJs = renderView( "admin/layout/ckeditorjs" );
	css        = event.renderIncludes( "css" );
	bottomJs   = event.renderIncludes( "js" );

	event.include( assetId="/js/admin/coretop/", group="top" );
	event.include( assetId="/js/admin/coretop/ie/", group="top" );
	topJs      = event.renderIncludes( "js", "top" );

	htmlTitle = translateResource( uri="cms:cms.title" ) & " :: " & ( prc.pageTitle ?: translateResource( uri="cms:cms.tagline", defaultValue="" ) );

	cfheader( name="cache-control", value="no-cache, no-store" );
	cfheader( name="expires",       value="Fri, 20 Nov 2015 00:00:00 GMT" );
</cfscript>

<cfoutput><!DOCTYPE html>
<html lang="en" class="presidecms">
	<head>
		<meta charset="utf-8" />
		<title>#htmlTitle#</title>
		<meta name="robots" content="NOINDEX,NOFOLLOW" />
		<meta name="description" content="" />
		<meta name="viewport" content="width=device-width, initial-scale=1.0" />

		<link rel="shortcut icon" type="image/x-icon" href="#event.buildLink( systemStaticAsset='/images/logos/favicon.png' )#">

		#css#
		#topJs#
	</head>

	<body class="preside-theme">
		<div class="outer-container">
			#navbar#
			#siteAlerts#

			<div class="main-container" id="main-container">
				<script type="text/javascript">
					try{ace.settings.check('main-container' , 'fixed')}catch(e){}
				</script>

				<div class="main-container-inner">
					<a class="menu-toggler" id="menu-toggler" href="##">
						<span class="menu-text"></span>
					</a>
					#breadcrumbs#

					#sideBarNav#
					<div class="main-content">

						<div class="page-content">
							#renderView( view="admin/general/pageTitle", args={
								  title    = ( prc.pageTitle    ?: "" )
								, subTitle = ( prc.pageSubTitle ?: "" )
								, icon     = ( prc.pageIcon     ?: "" )
							} )#

							<div class="row">
								<div class="col-xs-12">
									#body#
								</div>
							</div>
						</div>

					</div>
				</div>
			</div>
			#footer#
		</div>

		#notifications#

		#ckEditorJs#

		#bottomJs#
	</body>
</html></cfoutput>