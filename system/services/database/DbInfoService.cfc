/**
 * Proxy to cfdbinfo for returning information about a database and its objects
 *
 * @singleton
 */
component {

// CONSTRUCTOR

	/**
	 * @baseEngine.inject   baseEngine
	 *
	 */
	public any function init( any baseEngine ) {
		_setcfmlBaseEngine( arguments.baseEngine );
		return this;
	}

// PUBLIC API METHODS
	public query function getDatabaseVersion( required string dsn ) {
		var db = "";

		cfdbinfo( type="version", datasource=arguments.dsn, name="db" );
		return db;
	}

	public query function getTableInfo( required string tableName, required string dsn ) {
		var table = "";

		cfdbinfo( type="tables", name="table", pattern="#arguments.tableName#", datasource="#arguments.dsn#" );
		return table;
	}

	public query function getTableColumns( required string tableName, required string dsn ) {
		var columns = "";

		cfdbinfo( type="columns", name="columns", table=arguments.tableName, datasource=arguments.dsn );

		return columns;
	}

	public struct function getTableIndexes( required string tableName, required string dsn ) {
		var indexes = "";
		var index   = "";
		var ixs     = {};

		cfdbinfo( type="index", table="#arguments.tableName#", name="indexes", datasource="#arguments.dsn#" );

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
		var key         = "";
		var constraints = {};
		var rules       = _getcfmlBaseEngine().getFKRules();

		cfdbinfo( type="foreignKeys", table=arguments.tableName, datasource="#arguments.dsn#", name="keys" );

		if( ( server.coldfusion.productName ?: "" ) eq "ColdFusion Server" ) {
			var getFkName = arguments.Fk_name ?: QueryNew("");
			keys          = _getcfmlBaseEngine().populateKeys( getFkName, keys, arguments.tableName );
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

	// GETTERS AND SETTERS
	private any function _getcfmlBaseEngine() {
		return _setcfmlBaseEngine;
	}
	private any function _setcfmlBaseEngine( required any baseEngine ) {
		_setcfmlBaseEngine = arguments.baseEngine;
	}
}