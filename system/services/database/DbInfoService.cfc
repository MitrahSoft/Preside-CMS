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
		var fk_value = new Query();
//It should be migrated into BaseAdapter
		fk_value.setDatasource("#application.dsn#");
		fk_value.setSQL( "SELECT CONSTRAINT_NAME,TABLE_NAME FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = 'preside_test' AND CONSTRAINT_TYPE = 'FOREIGN KEY'" );
		var getFkName = fk_value.execute().getResult();

		rules["0"] = "cascade";
		rules["2"] = "set null";
		for( fkName in getFkName ) {
			for( key in keys ) {
				if( fkName.table_name eq key.fktable_name ){
					constraints[ fkName.constraint_name ] = {
						  pk_table  = arguments.table
						, fk_table  = key.fktable_name
						, pk_column = key.pkcolumn_name
						, fk_column = key.fkcolumn_name
					};

					if ( StructKeyExists( rules, key.update_rule ) ) {
						constraints[ fkName.constraint_name ].on_update = rules[ key.update_rule ];
					} else {
						constraints[ fkName.constraint_name ].on_update = "error";
					}

					if ( StructKeyExists( rules, key.delete_rule ) ) {
						constraints[ fkName.constraint_name ].on_delete = rules[ key.delete_rule ];
					} else {
						constraints[ fkName.constraint_name ].on_delete = "error";
					}
				}
			}
		}

		return constraints;
	}
}