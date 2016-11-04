/**
 * Proxy to cfdbinfo for returning information about a database and its objects
 *
 * @singleton
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public query function getDatabaseVersion( required string dsn ) {

		return new dbinfo( datasource="#arguments.dsn#" ).version();
	}

	public query function getTableInfo( required string tableName, required string dsn ) {

		return new dbinfo( datasource="#arguments.dsn#", pattern="#arguments.tableName#" ).tables();
	}

	public query function getTableColumns( required string tableName, required string dsn ) {

		return new dbinfo( datasource="#arguments.dsn#", table="#arguments.tableName#" ).columns();
	}

	public struct function getTableIndexes( required string tableName, required string dsn ) {
		var indexes = new dbinfo( datasource="#arguments.dsn#", table="#arguments.tableName#" ).index();
		var index   = "";
		var ixs     = {};

		for( index in indexes ){
			if ( Len( Trim( index.index_name ) ) && index.index_name != "PRIMARY" ) {
				if ( !StructKeyExists( ixs, index.index_name ) ){
					ixs[ index.index_name ] = {
						  unique = !( IsBoolean( index.non_unique ) && index.non_unique )
						, fields = ""
					};
				}

				ixs[ index.index_name ].fields = ListAppend( ixs[ index.index_name ].fields, index.column_name );
			}
		}

		return ixs;
	}

	public struct function getTableForeignKeys( required string tableName, required string dsn, query Fk_name ) {
		var fkName      = "";
		var key         = "";
		var constraints = {};
		var rules       = {};
		var fk_value    = new Query();
		rules["0"]      = "cascade";
		rules["2"]      = "set null";
		if( ( server.coldfusion.productName ?: "" ) eq "ColdFusion Server" ) {
			var keys      = new dbinfo( datasource="#arguments.dsn#", table="#arguments.tableName#" ).foreignKeys();
			var getFkName = arguments.Fk_name ?: QueryNew("");
			QueryAddColumn( keys, "FK_NAME", arrayNew(1) );
			QueryAddColumn( keys, "PKTABLE_NAME", arrayNew(1) );
			for( fk in getFkName ) {
				for( key in keys ){
					if( fk.table_name eq key.fktable_name ) {
						QuerySetCell( keys, "FK_NAME", fk.constraint_name, keys.currentRow );
						QuerySetCell( keys, "PKTABLE_NAME", arguments.tableName, keys.currentRow );
					}
				}
			}
		} else {
			cfdbinfo( type="foreignKeys", table="#arguments.tableName#", name="keys", datasource="#arguments.dsn#" );
		}

		for( key in keys ){
			constraints[ key.fk_name ] = {
				  pk_table  = key.pktable_name
				, fk_table  = key.fktable_name
				, pk_column = key.pkcolumn_name
				, fk_column = key.fkcolumn_name
			};

			if ( StructKeyExists( rules, key.update_rule ) ) {
				constraints[ key.fk_name ].on_update = rules[ key.update_rule ];
			} else {
				constraints[ key.fk_name ].on_update = "error";
			}

			if ( StructKeyExists( rules, key.delete_rule ) ) {
				constraints[ key.fk_name ].on_delete = rules[ key.delete_rule ];
			} else {
				constraints[ key.fk_name ].on_delete = "error";
			}
		}
		return constraints;
	}

}