/**
 * @singleton
 *
 */
component extends="BaseAdapter" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public string function escapeEntity( required string entityName ) {
		var escaped = "[#arguments.entityName#]";

		return Replace( escaped, ".", "].[", "all" );
	}

	public string function getColumnDefinitionSql(
		  required string   columnName
		, required string   dbType
		,          numeric  maxLength     = 0
		,          boolean  nullable      = true
		,          boolean  primaryKey    = false
		,          boolean  autoIncrement = false

	) {
		var columnDef  = escapeEntity( arguments.columnName )
		var isNullable = not arguments.primaryKey and ( arguments.nullable or StructKeyExists( arguments, 'defaultValue' ) );

		switch( arguments.dbType ) {
			case "boolean":
				columnDef &= "bit";
				break;
			case "timestamp":
				columnDef &= "datetime";
				break;
			case "longtext":
				columnDef &= "text";
				break;
			case "bigint":
			case "int":
			case "float":
			case "double":
			case "text":
				arguments.maxLength = 0;
				columnDef &= "#arguments.dbType#";
				break;
			default:
				columnDef &= "#arguments.dbType#";
				break;
		}

		if ( arguments.dbType eq "varchar" and not arguments.maxLength ) {
			arguments.maxLength = 200;
		}

		if ( arguments.maxLength ) {

			columnDef &= "(#arguments.maxLength#)";
		}

		columnDef &= ( isNullable ? " null" : " not null" );

		if ( arguments.autoIncrement ) {
			columnDef &= " IDENTITY(1,1)";
		}

		if ( arguments.primaryKey ) {
			columnDef &= " PRIMARY KEY";
		}

		return columnDef;
	}

	public string function getAlterColumnSql(
		  required string  tableName
		, required string  columnName
		, required string  dbType
		,          string  defaultValue
		,          numeric maxLength     = 0
		,          boolean nullable      = true
		,          boolean primaryKey    = false
		,          boolean autoIncrement = false
		,          string  newName       = arguments.columnName


	) {
		var columnDef = getColumnDefinitionSql(
			  columnName    = arguments.newName
			, dbType        = arguments.dbType
			, defaultValue  = arguments.defaultValue
			, maxLength     = arguments.maxLength
			, nullable      = arguments.nullable
			, autoIncrement = arguments.autoIncrement
		);

		return "alter table #escapeEntity( arguments.tableName )# alter column #columnDef#";
	}

	public string function getTableDefinitionSql( required string tableName, required string columnSql ) {
		return "create table #escapeEntity( arguments.tableName )# ( #arguments.columnSql# )";
	}

	public string function getForeignKeyConstraintSql(
		  required string sourceTable
		, required string sourceColumn
		, required string constraintName
		, required string foreignTable
		, required string foreignColumn
		,          string onDelete = "set null"
		,          string onUpdate = "cascade"
	) {
		var sql = "alter table #escapeEntity( arguments.sourceTable )#";

		sql &= " add constraint #escapeEntity( arguments.constraintName )#";
		sql &= " foreign key ( #escapeEntity( arguments.sourceColumn )# )";
		sql &= " references #escapeEntity( arguments.foreignTable )# ( #escapeEntity( arguments.foreignColumn )# )";

		// note, we do not allow `on update / on delete cascade` here due to SQL server's dim view of
		// them leading to 'may cause cycles or multiple cascade paths' errors

		return sql;
	}

	public string function getDropForeignKeySql( required string foreignKeyName, required string tableName) {
		return "alter table #escapeEntity( arguments.tableName )# drop constraint #escapeEntity( arguments.foreignKeyName )#";
	}

	public string function getDropIndexSql( required string indexName, required string tableName ) {
		return "drop index #escapeEntity( arguments.tableName )#.#escapeEntity( arguments.indexName )#";
	}

	public string function getUpdateSql(
		  required string tableName
		, required array  updateColumns
		, required any    filter
		,          string tableAlias = ""
		,          array  joins      = []
	) {
		var sql      = "update #escapeEntity( arguments.tableName )#";
		var delim    = "";
		var col      = "";
		var entity   = "";
		var hasAlias = Len( Trim( arguments.tableAlias ) );

		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, joins      = arguments.joins
			);
		}

		sql &= " set";

		for( col in arguments.updateColumns ) {
			entity = hasAlias and ListLen( col, '.' ) eq 1 ? "#col#" : col;
			sql &= delim & " " & escapeEntity( entity ) & " = :set__" & col;
			delim = ",";
		}

		if ( Len( arguments.tableAlias ) ) {
			sql &= " from #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )# ";
		}

		sql &= getClauseSql(
			filter     = arguments.filter,
			tableAlias = ""
		);

		return sql;
	}

	public string function getDeleteSql( required string tableName, required any filter, string tableAlias="" ) {
		var sql = "delete "

		if ( Len( Trim( arguments.tableAlias ) ) ) {
			sql &= "#escapeEntity( arguments.tableAlias )# from #escapeEntity( arguments.tableName )# as #escapeEntity( arguments.tableAlias )#";
		} else {
			sql &= "from #escapeEntity( arguments.tableName )#";
		}

		return sql & getClauseSql(
			  filter     = arguments.filter
			, tableAlias = arguments.tableAlias
		);
	}

	public string function getSelectSql(
		  required string  tableName
		, required array   selectColumns
		,          any     filter        = {}
		,          string  orderBy       = ""
		,          string  groupBy       = ""
		,          string  tableAlias    = ""
		,          array   joins         = []
		,          numeric maxRows       = 0
		,          numeric startRow      = 1

	) {
		var newGroupBy  = "";
		var sql         = "select";
		var delim       = " ";
		var col         = "";

		for( col in arguments.selectColumns ){
			if( Len( Trim( arguments.tableAlias ) ) && !FindNoCase( ".", col, 1 ) && Len( col ) > 1 && !containsAggregateFunctions( col ) ) {
				sql &= delim & arguments.tableAlias & "." & col;
			} else {
				sql &= delim & col;
			}
			delim = ", ";
		}
		if ( containsAggregateFunctions( sql ) ) {
			delim = " ";
			for( col in arguments.selectColumns ){
				if ( !containsAggregateFunctions( col ) ) {
					newGroupBy &= delim & REReplace(col, "as\s\w+", "", "one");
					delim = ", ";
				}
			}
		}

		if ( arguments.maxRows ) {
			if ( Len( Trim ( arguments.orderBy ) ) ) {
				if ( !containsAggregateFunctions( sql ) ) {
					sql &= ", row_number() over (order by " & arguments.orderBy & ") as row ";
				}
			}
		}

		sql &= " from " & escapeEntity( arguments.tableName );
		if ( Len( arguments.tableAlias ) ) {
			sql &= " " & escapeEntity( arguments.tableAlias );
		}

		if ( ArrayLen( arguments.joins ) ) {
			sql &= getJoinSql(
				  tableName  = arguments.tableName
				, tableAlias = arguments.tableAlias
				, joins      = arguments.joins
			);
		}

		sql &= getClauseSql( tableAlias = arguments.tableAlias, filter = arguments.filter );


		if ( Len( Trim ( arguments.groupBy ) ) ) {
			if ( containsAggregateFunctions( sql ) ) {
				sql &= " group by " & newGroupBy;
			} else {
				sql = reCompileGroupByForMsSql( sql, arguments.selectColumns, arguments.groupBy, arguments.tableAlias );
			}
		}

		if ( Len( Trim ( arguments.orderBy ) )  && !arguments.maxRows ) {
			if ( !containsAggregateFunctions( sql ) ) {
				sql &= " order by " & arguments.orderBy;
			}
		}

		if ( arguments.maxRows ) {
			if ( Len( Trim ( arguments.orderBy ) ) ) {
				sql = "select * from ( " & sql & " ) as Temp where row > #arguments.startRow-1# and row <= #arguments.maxRows#";
			} else {
				sql = Replace(sql, "select", "select top #arguments.maxRows#", "one");
			}
		}

		return sql;
	}

	public string function sqlDataTypeToCfSqlDatatype( required string sqlDataType ) {
		switch( arguments.sqlDataType ){
			case "text":
			case "mediumtext":
			case "longtext":
				return "cf_sql_longvarchar";

			default:
				return super.sqlDataTypeToCfSqlDatatype( argumentCollection=arguments );
		}
	}

	public string function getIfNullStatement( required string statement, required string alternativeStatement, required string alias ) {
		return "IsNull( #arguments.statement#, #arguments.alternativeStatement# ) as #arguments.alias#";
	}

	private string function reCompileGroupByForMsSql( string sql, array select, string groupBy, string tableAlias ) {
		var sqlNonGroupBy      = arguments.sql;
		var strNonGroupBy      = Replace( arguments.groupBy, "group by", "", "all" );
		var arrColumnInGroupBy = ListToArray( strNonGroupBy, ", " );
		var newSql             = "select";
		var delim              = " ";
		var col                = "";

		for( col in arrColumnInGroupBy ){
			newSql &= delim & col;
			delim  = ", ";
		}

		newSql = REReplace( arguments.sql, "select.*?from", newSql & " from ", "one" );
		newSql = " , ( " & newSql & " group by "  & strNonGroupBy & " ) as Temp ";
		delim = " ";

		if ( FindNoCase( "where", sqlNonGroupBy, 1 ) > 0 ) {
			newSql = Replace( sqlNonGroupBy, "where", newSql & " where ", "one" );
			for( col in arrColumnInGroupBy) {
				newSql &=" and " & col & " = " & " Temp." & REReplace( col, ".*?\.", "", "one" );
			}
		} else {
			newSql &= " where ";
			for( col in arrColumnInGroupBy ) {
				newSql &= delim & col & " = " & " Temp." & REReplace( col, ".*?\.", "", "one" );
				delim = " and ";
			}
		}

		return newSql;
	}

	private boolean function containsAggregateFunctions( required string sql ) {
		return ReFindNoCase( "\b(SUM|COUNT|AVG|MIN|MAX)\(", arguments.sql );
	}

	public string function getLengthFunctionSql( required string expression ) {
		return "Len( #expression# )";
	}
}