<cfscript>
	prc.pageIcon  = "group";
	prc.pageTitle = translateResource( uri="cms:usermanager.editUser.page.title", data=[ prc.record.known_as ?: "" ] );
	mergeFormName = rc.id == event.getAdminUserId() ? "preside-objects.security_user.admin.edit.self" : "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object            = "security_user"
		, id                = rc.id      ?: ""
		, record            = prc.record ?: {}
		, editRecordAction  = event.buildAdminLink( linkTo='userManager.editUserAction' )
		, mergeWithFormName = mergeFormName
		, cancelAction      = event.buildAdminLink( linkTo='usermanager.users' )
	} )#
</cfoutput>