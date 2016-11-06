component output="false" displayname=""  {
	public any function onMissingMethod(
		  required string missingMethodName
		, required struct missingMethodArguments
	){
		var returnVariable = "";
		if( isstruct(server) AND server.coldfusion.productname EQ "Lucee" ) {
			cfinvoke ( component="preside.system.cfmlEngine.lucee", method = "#arguments.missingMethodName#", returnVariable = "returnVariable", argumentCollection = "#arguments.missingMethodArguments#" );

		} else if ( isstruct(server) AND server.coldfusion.productname EQ "ColdFusion Server" ) {
			cfinvoke ( component="preside.system.cfmlEngine.acf", method = "#arguments.missingMethodName#", returnVariable = "returnVariable", argumentCollection = "#arguments.missingMethodArguments#" );
		}
		return returnVariable;
	}
}