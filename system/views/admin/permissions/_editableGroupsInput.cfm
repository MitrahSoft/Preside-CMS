<cfscript>
	param name="args.controlName"    type="string";
	param name="args.title"          type="string";
	param name="args.savedPerms"     type="array";
	param name="args.inheritedPerms" type="array";

	function savedPermsToValueList( required array savedPerms ) {
		var permsList = ArrayNew(1);

		for( var perm in savedPerms ) {
			ArrayAppend( permsList, perm.id );
		}

		return ArrayToList( permsList );
	}
</cfscript>

<cfoutput>
	<div class="col-sm-6">
		#renderFormControl(
			  name           = args.controlName
			, type           = "objectPicker"
			, object         = "security_group"
			, multiple       = true
			, layout         = ""
			, placeholder    = args.title
			, defaultValue   = savedPermsToValueList( args.savedPerms )
			, disabledValues = savedPermsToValueList( args.inheritedPerms )
			, ajax           = false
		)#
	</div>
</cfoutput>