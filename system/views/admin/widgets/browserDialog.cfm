<cfscript>
	widgets = structKeyExists( prc, 'widgets' ) && isQuery( prc.widgets ) ? prc.widgets : QueryNew('');

	prc.pageIcon     = "magic";
	prc.pageTitle    = translateResource( uri="cms:widget.dialog.browser.title" );
	prc.pageSubTitle = translateResource( uri="cms:widget.dialog.browser.description" );
</cfscript>

<cfsavecontent variable="body">
	<cfif not widgets.recordCount>
		<cfoutput>
			<p><em>#translateResource( uri="cms:widget.dialog.browser.none.configured" )#</em></p>
		</cfoutput>
	<cfelse>
		<div id="widget-list" class="widget-list">
			<cfoutput>
				<div class="well well-sm">
					<div class="row">
						<div class="col-xs-12 col-sm-12 col-m-12">
							<form class="widget-search" data-auto-focus-form="true">
								<span class="input-icon">
									<input class="search-box search" type="text" placeholder="#translateResource( uri='cms:widget.dialog.browser.search.placeholder' )#">
									<i class="fa fa-search nav-search-icon"></i>
								</span>
							</form>
						</div>
					</div>
				</div>
			</cfoutput>
			<ul class="list-unstyled clearfix list" data-nav-list="1" data-nav-list-child-selector="li">
				<cfoutput query="widgets">
					<cfset widgetLink = event.buildAdminLink( linkTo="widgets.dialog", queryString="widget=#widgets.id#") />
					<li>
						<div class="pull-left widget-icon-container">
							<a href="#widgetLink#" class="widget-image-link">
								<i class="fa #widgets.icon# fa-4x"></i>
							</a>
						</div>
						<div class="pull-left widget-text-container">
							<h4 class="smallest">
								<a href="#widgetLink#" class="widget-title">
									#widgets.title#
								</a>
							</h4>
							<p class="widget-description">#widgets.description#</p>
						</div>
					</li>
				</cfoutput>
			</ul>
		</div>
	</cfif>
</cfsavecontent>
<cfoutput>
	#renderView( view="/admin/widgets/_dialogLayout", args={ body=body } )#
</cfoutput>