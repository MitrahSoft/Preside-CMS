<cfparam name="args.locales"        type="array">
<cfparam name="args.selectedLocale" type="struct">

<cfif args.locales.len()>
	<cfoutput>
		<a data-toggle="dropdown" href="##" class="dropdown-toggle admin-locale-picker-link">
			<img src="/preside/system/assets/images/flags/16x16/#args.selectedLocale.flag#" class="locale-flag" />
			#args.selectedLocale.title#
			<i class="fa fa-fw fa-caret-down"></i>
		</a>

		<ul class="admin-locale-picker dropdown-menu dropdown-caret pull-right dropdown-close dropdown-yellow">
			<cfloop array="#args.locales#" item="locale" index="i">
				<li <cfif locale.selected>class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo='login', querystring='l=#locale.locale#&callBack=#event.getCurrentHandler()#.#event.getCurrentAction()#' )#" class="locale-link">
						<span class="flag-and-title">
							<img src="/preside/system/assets/images/flags/16x16/#locale.flag#" class="locale-flag" />
							#locale.title#
						</span>
					</a>
				</li>
			</cfloop>
		</ul>
	</cfoutput>
</cfif>