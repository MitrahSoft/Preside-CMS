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

	public struct function getTableForeignKeys( required string tableName, required string dsn ) {
		var keys        = new dbinfo( datasource="#arguments.dsn#", table="#arguments.tableName#" ).foreignKeys();
		var key         = "";
		var constraints = {};
		var rules       = {};

		rules["0"] = "cascade";
		rules["2"] = "set null";

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