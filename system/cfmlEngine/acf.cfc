/**
*
* @file
* @author
* @description
*
*/

component output="false" displayname=""  {

	public function populateKeys( getFkName, keys, table ){
		var fkName = "";
		var key    = "";
		var _keys  = arguments.keys;

		QueryAddColumn( _keys, "FK_NAME", arrayNew(1) );
		QueryAddColumn( _keys, "PKTABLE_NAME", arrayNew(1) );
		for( fkName in arguments.getFkName ) {
			for( key in _keys ) {
				if( fkName.table_name eq key.fktable_name ) {
					QuerySetCell( _keys, "FK_NAME", fkName.constraint_name, _keys.currentRow );
					QuerySetCell( _keys, "PKTABLE_NAME", arguments.table, _keys.currentRow );
					QuerySetCell( _keys, "update_rule", fkName.update_rule, _keys.currentRow );
					QuerySetCell( _keys, "delete_rule", fkName.delete_rule, _keys.currentRow );
				}
			}
		}
		return _keys;
	}

	public function getFKRules(){
		return { "cascade"  = "cascade", "set null" = "set null" };
	}

	public function deleteSchedule(taskName){

		cfschedule( action="list", task=arguments.taskName, result="result" );
		if( result.recordCount )
			cfschedule( action="delete", task=arguments.taskName );

		return true;
	}

	public function getAntiSamyObject(jarFolderPath){
		return CreateObject( "java", "org.owasp.validator.html.AntiSamy" );
	}

}