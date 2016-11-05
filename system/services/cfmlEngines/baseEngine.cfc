<cfcomponent output="false" displayname=""  >

	<cffunction name="onMissingMethod" returntype="any" access="public" output="false" hint="This method handles dynamic finders, properties, and association methods. It is not part of the public API.">
		<cfargument name="missingMethodName" type="string" required="true" hint="Name of method attempted to load.">
		<cfargument name="missingMethodArguments" type="struct" required="true" hint="Name/value pairs of arguments that were passed to the attempted method call.">

		<cfset returnVariable = "">

		<cfif isstruct(server) AND server.coldfusion.productname EQ "Lucee">
			<cfinvoke component="preside.system.cfmlEngine.lucee" method="#arguments.missingMethodName#" argumentcollection="#arguments.missingMethodArguments#" returnvariable="returnVariable" >
			</cfinvoke>
		<cfelseif isstruct(server) AND server.coldfusion.productname EQ "ColdFusion Server">
			<cfinvoke component="preside.system.cfmlEngine.acf" method="#arguments.missingMethodName#" argumentcollection="#arguments.missingMethodArguments#" returnvariable="returnVariable" >
			</cfinvoke>
		</cfif>

		<cfreturn returnVariable>
	</cffunction>
</cfcomponent>