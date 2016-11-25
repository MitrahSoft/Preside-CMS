component {

	this.name = "Preside Test Suite " & Hash( ExpandPath( '/' ) );

	currentDir = GetDirectoryFromPath( GetCurrentTemplatePath() );


	this.mappings['/tests']       = currentDir;
	this.mappings['/integration'] = currentDir & "integration";
	this.mappings['/resources']   = currentDir & "resources";
	this.mappings['/testbox']     = currentDir & "testbox";
	this.mappings['/mxunit' ]     = currentDir & "testbox\system\compat";
	this.mappings['/app']         = currentDir & "resources\testSite";
	this.mappings['/preside']     = currentDir & "..\..\";
	this.mappings['/coldbox']     = currentDir & "..\..\system\externals\coldbox-standalone-3.8.2\coldbox";
	this.sessionmanagement        = true;
	this.javaSettings             = { LoadPaths = [ expandPath("..\..\system/services\encryption\bcrypt\lib\jbcrypt-0.3m.jar"), expandPath( "..\..\system/services\qrcodes\lib\QRGen\" ), expandPath( "..\..\system/services\qrcodes\lib\zxing\" ), expandPath("..\..\system/services\assetManager\xmp\xmpcore.jar"), expandPath("..\..\system/services\taskmanager\lib\"), expandPath("..\..\system/services\security\antisamylib\") ], loadColdFusionClassPath = true, reloadOnChange= false };
	setting requesttimeout="6000";
	_loadDsn();

	function onApplicationStart() {
		if ( !_checkDsn() ) {
			return false;
		}
		return true;
	}

	function onRequestStart() {
		if ( StructKeyExists( url, 'fwreinit' ) ) {
			_loadDsn();
		}

		return true;
	}

	private boolean function _checkDsn() {
		var dsn  = "preside_test_suite";
		try {
			cfdbinfo( datasource="#dsn#", name="info", type="version" );

		} catch ( database e ) {
			var isCommandLineExecuted = cgi.server_protocol == "CLI/1.0";
			var nl          = isCommandLineExecuted ? Chr( 13 ) & Chr( 10 ) : "<br>";
			var errorDetail =  "Test datasource not setup. By default, the testsuite will look for a MySQL database with the following details: " & nl & nl;
			    errorDetail &= "Host     : localhost"    & nl;
			    errorDetail &= "Port     : 3306"         & nl;
			    errorDetail &= "DB Name  : preside_test" & nl;
			    errorDetail &= "User     : root"         & nl;
			    errorDetail &= "Password : (empty)"      & nl;

			    errorDetail &= nl & "These defaults can be overwritten by setting the following environment variables: " & nl & nl;
			    errorDetail &= "PRESIDETEST_DB_HOST"     & nl;
			    errorDetail &= "PRESIDETEST_DB_PORT"     & nl;
			    errorDetail &= "PRESIDETEST_DB_NAME"     & nl;
			    errorDetail &= "PRESIDETEST_DB_USER"     & nl;
			    errorDetail &= "PRESIDETEST_DB_PASSWORD" & nl;

			if ( isCommandLineExecuted ) {
				echo( errorDetail );
				return false;
			} else {
				throw(
					  type    = "presidetestsuite.nodsn"
					, message = "No datasource has been created for the test suite."
					, detail  = errorDetail
				);
			}
		}

		switch( info.database_productname ) {
			case "MySQL":
				if ( Val( info.database_version ) lt 5 ) {
					throw(
						  type    = "presideTestSuite.invalidDsn"
						, message = "Invalid Datasource. Only MySQL version 5 and above is supported at this time."
						, detail  = "The db product of the datasource is reported as: #info.database_productname# #info.database_version#"
					);
				}
				break;
			case "Microsoft SQL Server":
				break;
			case "PostgreSQL":
				break;
			default:
				throw(
					  type    = "presideTestSuite.invalidDsn"
					, message = "Invalid Datasource. Only MySQL (version 5 and above) and Microsoft SQL Server are supported at this time."
					, detail  = "The db product of the datasource is reported as: #info.database_productname# #info.database_version#"
				);
		}

		application.dsn = dsn;
		application.databaseName = "preside_test_suite";

		return true;
	}

	private void function _loadDsn() {
		if ( _dsnExists() ) {
			return;
		}

		var dbConfig = {
			  port     = _getEnvironmentVariable( "PRESIDETEST_DB_PORT"    , "3306" )
			, host     = _getEnvironmentVariable( "PRESIDETEST_DB_HOST"    , "localhost" )
			, database = _getEnvironmentVariable( "PRESIDETEST_DB_NAME"    , "preside_test" )
			, username = _getEnvironmentVariable( "PRESIDETEST_DB_USER"    , "root" )
			, password = _getEnvironmentVariable( "PRESIDETEST_DB_PASSWORD", "" )
		};

		try {
			this.datasources[ "preside_test_suite" ] = {
				  type     : 'MySQL'
				, port     : dbConfig.port
				, host     : dbConfig.host
				, database : dbConfig.database
				, username : dbConfig.username
				, password : dbConfig.password
				, custom   : {
					  characterEncoding : "UTF-8"
					, useUnicode        : true
				  }
			};
		} catch( any e ) {}
	}

	private string function _getEnvironmentVariable( required string variableName, string defaultValue="" ) {
		var result = CreateObject("java", "java.lang.System").getenv().get( arguments.variableName );

		return IsNull( result ) ? arguments.defaultValue : result;
	}

	private boolean function _dsnExists() {
		try {
			cfdbinfo( datasource="preside_test_suite", name="info", type="version" );

			return info.recordcount > 0;
		} catch ( database e ) {
			return false;
		}
	}
}