component output="false" displayname=""  {
	public any function onMissingMethod(
		  required string missingMethodName
		, required struct missingMethodArguments
	){
		if( isstruct(server) AND server.coldfusion.productname EQ "Lucee" ) {
			return invoke ( "preside.system.cfmlEngine.lucee", "#arguments.missingMethodName#", "#arguments.missingMethodArguments#" );

		} else if ( isstruct(server) AND server.coldfusion.productname EQ "ColdFusion Server" ) {
			return invoke ( "preside.system.cfmlEngine.acf","#arguments.missingMethodName#", "#arguments.missingMethodArguments#" );
		}
	}
}