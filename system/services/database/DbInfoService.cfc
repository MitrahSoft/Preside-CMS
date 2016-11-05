<cfcomponent output="false" singleton="true">
	<cffunction name="init" access="public" returntype="any">
		<cfreturn this>
	</cffunction>

	<cffunction name="getDatabaseVersion" access="public" returntype="Query">
		<cfargument name="dsn" type="string" required="true">
			<cfdbinfo type="version" name="db" datasource="#arguments.dsn#" />
			<cfreturn db>
	</cffunction>

	<cffunction name="getTableInfo" access="public" returntype="Query">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="dsn" type="string" required="true">
			<cfdbinfo type="tables" datasource="#arguments.dsn#" pattern="#arguments.tableName#" name="tableInfo" />
		<cfreturn tableInfo>
	</cffunction>

	<cffunction name="getTableColumns" access="public" returntype="Query">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="dsn" type="string" required="true">
		<cfdbinfo type="columns" table="#arguments.tableName#" name="columns" datasource="#arguments.dsn#" />
		<cfreturn columns>
	</cffunction>

	<cffunction name="getTableIndexes" access="public" returntype="Struct">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="dsn" type="string" required="true">
		<cfdbinfo type="index" table="#arguments.tableName#" name="indexes" datasource="#arguments.dsn#" />
		<cfscript>
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
		</cfscript>
	</cffunction>

	<cffunction name="getTableForeignKeys" access="public" returntype="struct" output="false">
		<cfargument name="tableName" type="string" required="true" >
		<cfargument name="dsn"       type="string" required="true">
		<cfargument name="Fk_name"   type="string" required="false">
		<cfdbinfo type="Foreignkeys" table="#arguments.tableName#" name="keys" datasource="#arguments.dsn#" />

		<cfscript>
			var fk            = "";
			var key           = "";
			var constraints   = {};
			var rules         = {};
			rules["0"]        = "cascade";
			rules["cascade"]  = "cascade";
			rules["2"]        = "set null";
			rules["set null"] = "set null";

			if( ( server.coldfusion.productName ?: "" ) eq "ColdFusion Server" ) {
				var getFkName = arguments.Fk_name ?: QueryNew("");
				QueryAddColumn( keys, "FK_NAME", arrayNew(1) );
				QueryAddColumn( keys, "PKTABLE_NAME", arrayNew(1) );
				for( fk in getFkName ) {
					for( key in keys ){
						if( fk.table_name eq key.fktable_name ) {
							QuerySetCell( keys, "FK_NAME", fk.constraint_name, keys.currentRow );
							QuerySetCell( keys, "PKTABLE_NAME", arguments.tableName, keys.currentRow );
							QuerySetCell( keys, "update_rule", fkName.update_rule, keys.currentRow );
							QuerySetCell( keys, "delete_rule", fkName.delete_rule, keys.currentRow );
						}
					}
				}
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
		</cfscript>
	</cffunction>
</cfcomponent>