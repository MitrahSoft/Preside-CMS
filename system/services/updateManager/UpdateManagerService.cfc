/**
 * The Update Manager Service provides the APIs
 * for managing the installed version of core Preside
 * for your application.
 *
 * @singleton
 *
 */
component {

// constructor
	/**
	 * @repositoryUrl.inject              coldbox:setting:updateRepositoryUrl
	 * @systemConfigurationService.inject systemConfigurationService
	 * @applicationReloadService.inject   applicationReloadService
	 * @lookupCache.inject                cachebox:DefaultQueryCache
	 *
	 */
	public any function init(
		  required string repositoryUrl
		, required any    systemConfigurationService
		, required any    applicationReloadService
		, required any    lookupCache
		,          string presidePath="/preside"

	) {
		_setRepositoryUrl( arguments.repositoryUrl );
		_setSystemConfigurationService( arguments.systemConfigurationService );
		_setApplicationReloadService( arguments.applicationReloadService );
		_setPresidePath( arguments.presidePath );
		_setLookupCache( arguments.lookupCache );
		_setActiveDownloads( {} );

		return this;
	}

// public methods
	public string function getCurrentVersion() {
		var versionFile = ListAppend( _getPresidePath(), "version.json", "/" );
		var versionInfo = "";
		if ( !FileExists( expandpath( versionFile ) ) ) {
			return "unknown";
		}

		try {
			versionInfo = DeSerializeJson( FileRead( expandpath( versionFile ) ) );
		} catch ( any e ) {
			return "unknown";
		}

		return versionInfo.version ?: "unknown";
	}

	public boolean function isGitClone() {
		var gitDir = _getPresidePath() & "/.git/";

		return getCurrentVersion() == "unknown" && DirectoryExists( gitDir );
	}

	public string function getGitBranch() {
		var headFile = _getPresidePath() & "/.git/HEAD";

		if ( FileExists( headFile ) ) {
			try {
				var head = FileRead( headFile );

				return Trim( ReReplace( head, "^ref: refs\/heads\/", "" ) );
			} catch( any e ){
				"unknown";
			}
		}

		return "unknown";
	}

	public struct function getLatestVersion() {
		var versions = listAvailableVersions();

		if ( versions.len() ) {
			versions.sort( function( a, b ){
				return compareVersions( a.version, b.version );
			} );

			return versions[ versions.len() ];
		}


		return { version = "unknown" };
	}

	public array function listAvailableVersions() {
		var cache    = _getLookupCache();
		var cacheKey = "UpdateManagerService.listAvailableVersions";
		var cached   = cache.get( cacheKey );

		if ( !IsNull( cached ) ) {
			return cached;
		}

		var s3Listing         = "";

		try {
			s3Listing = _fetchS3BucketListing();
		} catch ( any e ) {
			return [];
		}

		var branchPath        = _getRemoteBranchPath();
		var xPath             = "//*[local-name()='ListBucketResult']/*[local-name()='Contents']/*[local-name()='Key' and starts-with(.,""#branchPath#"")]";
		var versionFiles= XmlSearch( s3Listing, xPath );
		var jsonAndZipMatches = {};
		var versions          = [];

		for( var versionFilePath in versionFiles ) {
			versionFilePath = versionFilePath.xmlText;

			if ( ReFindNoCase( "\.(zip|json)$", versionFilePath ) ) {
				var fileKey  = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\1" );
				var fileType = ReReplace( versionFilePath, "^(.*)\.(zip|json)$", "\2" );

				jsonAndZipMatches[ fileKey ][ fileType ] = true;
			}
		}

		for( var fileKey in jsonAndZipMatches ) {
			if ( jsonAndZipMatches[ fileKey ].keyExists( "json" ) && jsonAndZipMatches[ fileKey ].keyExists( "zip" ) ) {
				var versionInfo = _fetchVersionInfo( fileKey & ".json" );
				versionInfo.path = fileKey & ".zip";
				versionInfo.downloaded = versionIsDownloaded( versionInfo.version );

				versions.append( versionInfo );
			}
		}

		cache.set( cacheKey, versions );

		return versions;
	}

	public array function listDownloadedVersions() {
		var containerDirectory = _getVersionContainerDirectory();
		var childDirectories   = DirectoryList( expandpath ( containerDirectory ), false, "query" );
		var versions           = [];

		for( var dir in childDirectories ){
			if ( dir.type == "Dir" ) {
				var versionFile = containerDirectory & dir.name & "/version.json";
				if ( FileExists( expandpath( versionFile ) ) ) {
					try {
						var versionInfo = DeSerializeJson( FileRead( expandpath( versionFile ) ) );
						versionInfo.path = ExpandPath( containerDirectory & dir.name );
						versions.append( versionInfo );
					} catch( any e ) {}
				}
			}
		}

		versions.sort( function( a, b ){
			return compareVersions( a.version, b.version );
		} );

		return versions;
	}

	public boolean function versionIsDownloaded( required string version ) {
		var versions = listDownloadedVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				return true;
			}
		}

		return false;
	}

	public struct function listDownloadingVersions() {
		return _getActiveDownloads();
	}

	public void function downloadVersion( required string version ) {
		if ( _getActiveDownloads().keyExists( arguments.version ) ) {
			throw( type="UpdateManagerService.download.already.in.progress", message="Version [#arguments.version#] is already being downloaded" );
		}

		var versions = listAvailableVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				var downloadUrl = _getRepositoryUrl() & "/" & v.path;

				return _downloadAndUnpackVersionAsynchronously( v.version, downloadUrl );
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found in the [#_getSetting( 'branch', 'release' )#] branch" );
	}

	public void function clearDownload( required string version ) {
		var activeDownloads = listDownloadingVersions();

		activeDownloads.delete( arguments.version );
	}

	public boolean function downloadIsActive( required string version, required string downloadId ) {
		var activeDownloads = listDownloadingVersions();

		return ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId;
	}

	public boolean function downloadIsComplete( required string version ) {
		var activeDownloads = listDownloadingVersions();

		return activeDownloads[ arguments.version ].complete ?: true;
	}

	public void function markDownloadAsErrored( required string version, required string downloadId, required struct error ) {
		var activeDownloads = listDownloadingVersions();
		if ( ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId ) {
			activeDownloads[ arguments.version ].complete = true;
			activeDownloads[ arguments.version ].success  = false;
			activeDownloads[ arguments.version ].error    = arguments.error;
		}
	}
	public void function markDownloadAsComplete( required string version, required string downloadId ) {
		var activeDownloads = listDownloadingVersions();
		if ( ( activeDownloads[ arguments.version ].id ?: "" ) == arguments.downloadId ) {
			activeDownloads[ arguments.version ].complete = true;
			activeDownloads[ arguments.version ].success  = true;
		}
	}

	public boolean function installVersion( required string version ) {
		var versions       = listDownloadedVersions();
		var currentVersion = getCurrentVersion();

		for( var v in versions ){
			if ( v.version == arguments.version ) {
				_runDowngradeScripts( arguments.version, currentVersion );
				_updateMapping( v.path );
				_runUpgradeScripts( arguments.version, currentVersion );
				_getApplicationReloadService().reloadAll();

				return true;
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found locally" );
	}

	public boolean function deleteVersion( required string version ) {
		if ( arguments.version == getCurrentVersion() ) {
			throw( type="UpdateManagerService.cannot.delete.current.version", message="You cannot delete the currently installed version, [#arguments.version#] from the server" );
		}
		var versions = listDownloadedVersions();
		for( var v in versions ){
			if ( v.version == arguments.version ) {
				try {
					DirectoryDelete( v.path, true );

					return true;
				} catch( any e ) {
					throw( type="UpdateManagerService.failed.to.delete", message=e.message );
				}
			}
		}

		throw( type="UpdateManagerService.unknown.version", message="Version [#arguments.version#] could not be found locally" );
	}

	public struct function getSettings() {
		return _getSystemConfigurationService().getCategorySettings( category="updatemanager" );
	}

	public void function saveSettings( required struct settings ) {
		var cfgService = _getSystemConfigurationService();

		for( var key in arguments.settings ) {
			cfgService.saveSetting( category="updatemanager", setting=key, value=arguments.settings[ key ] );
		}
	}

	public numeric function compareVersions( required string versionA, required string versionB ) {
		if ( versionA == versionB ) {
			return 0;
		}

		var a = ListToArray( versionA, "." );
		var b = ListToArray( versionB, "." );

		for( var i=1; i <= a.len(); i++ ) {
			if ( b.len() < i ) {
				return 1;
			}
			if ( a[i] > b[i] ) {
				return 1;
			}
			if ( a[i] < b[i] ) {
				return -1;
			}
		}

		return -1;
	}

// private helpers
	private xml function _fetchS3BucketListing() {
		return XmlParse( _getRepositoryUrl() );
	}

	private struct function _fetchVersionInfo( required string versionFilePath ) ouptut=false {
		var result = "";
		var versionFileUrl = ListAppend( _getRepositoryUrl(), arguments.versionFilePath, "/" );
		var noteURL = 'https://www.presidecms.com/release-notes/release-notes-for-';

		try {
			cfhttp ( url=versionFileUrl, result="result", throwOnError=true );
			resultData = DeSerializeJson(result.fileContent);
			resultData.date = result.responseheader['Last-Modified'];
			// Release notes only available after 10.1.1 in https://www.presidecms.com/release-notes/release-notes-for-10-1-1.html
			if ( compareVersions( resultData.version, '10.1.1' ) > 0 ){
				resultData.noteURL = noteURL & ListChangeDelims(ListDeleteAt( resultData.Version, ListFind(resultData.Version,listlast(resultData.Version,'.'),"."), "."),'-','.') & '.html';
			} else {
				resultData.noteURL = "-";
			}
			return resultData ;
		} catch ( any e ) {
			return { version="unknown" };
		}


	}

	private string function _getRemoteBranchPath() {
		var branch = _getSetting( setting="branch", default="release" );
		var path   = "presidecms/";

		switch( branch ) {
			case "bleedingEdge": return path & "bleeding-edge/";
			case "stable"      : return path & "stable/";
		}

		return path & "release/";
	}

	private string function _getSetting( required string setting, any default="" ) {
		return _getSystemConfigurationService().getSetting( category="updatemanager", setting=arguments.setting, default=arguments.default );
	}

	private string function _getVersionContainerDirectory() {
		var presideDirectory = _getPresidePath();
		return presideDirectory & "/../";
	}

	private void function _downloadAndUnpackVersionAsynchronously( required string version, required string downloadUrl ) {
		var tempPath        = getTempDirectory() & "/" & CreateUUId() & ".zip";
		var downloadId      = CreateUUId();
		var activeDownloads = _getActiveDownloads();

		activeDownloads[ arguments.version ] = { complete=false, success=false, id=downloadId };

		thread name=downloadId downloadId=downloadId downloadUrl=arguments.downloadUrl unpackToDir=_getVersionContainerDirectory() downloadPath=tempPath updateManagerService=this version=arguments.version {
			try {
				cfhttp( url=attributes.downloadUrl, path=attributes.downloadPath, throwOnError=true, timeout=Val( _getSetting( "download_timeout", 120 ) ) );
			} catch ( any e ) {
				attributes.updateManagerService.markDownloadAsErrored( attributes.version, attributes.downloadId, e );
				abort;
			}

			if ( attributes.updateManagerService.downloadIsActive( attributes.version, attributes.downloadId ) ) {
				try {
					cfzip( action="unzip", file=attributes.downloadPath, destination=attributes.unpackToDir );
				} catch( any e ) {
					attributes.updateManagerService.markDownloadAsErrored( attributes.version, attributes.downloadId, e );
					abort;
				}

				attributes.updateManagerService.markDownloadAsComplete( attributes.version, attributes.downloadId );

				try {
					FileDelete( attributes.downloadPath );
				} catch ( any e ) {}
			}
		}
	}

	private void function _updateMapping( required string newPath ) {
		try {
			cfadmin(  action   = "updateMapping"
			        , password = _getSetting( "railo_admin_pw", "password" )
			        , type     = "web"
			        , virtual  = "/preside"
			        , physical = arguments.newPath
			        , archive  = ""
			        , primary  = "physical"
			        , trusted  = true
			        , toplevel = false );

			pagePoolClear();
		} catch( "security" e ) {
			throw( type="UpdateManagerService.railo.admin.secured", message=e.message );
		}
	}

	private void function _runDowngradeScripts( required string newVersion, required string currentVersion ) {
		var newVersionWithoutBuild     = _getVersionWithoutBuildNumber( arguments.newVersion );
		var currentVersionWithoutBuild = _getVersionWithoutBuildNumber( arguments.currentVersion );

		if ( compareVersions( newVersionWithoutBuild, currentVersionWithoutBuild ) < 0 ) {
			_runMigrations( "downgrade", newVersionWithoutBuild, currentVersionWithoutBuild );
		}
	}

	private void function _runUpgradeScripts( required string newVersion, required string currentVersion ) {
		var newVersionWithoutBuild     = _getVersionWithoutBuildNumber( arguments.newVersion );
		var currentVersionWithoutBuild = _getVersionWithoutBuildNumber( arguments.currentVersion );

		if ( compareVersions( newVersionWithoutBuild, currentVersionWithoutBuild ) > 0 ) {
			_runMigrations( "upgrade", newVersionWithoutBuild, currentVersionWithoutBuild );
		}
	}

	private string function _getVersionWithoutBuildNumber( required string version ) {
		return ListDeleteAt( arguments.version, ListLen( arguments.version, "." ), "." );
	}

	private string function _runMigrations( required string type, required string newVersion, required string currentVersion ) {
		var migrationType      = arguments.type == "upgrade" ? "upgrade" : "downgrade";
		var parentDirectory    = "/preside/system/migrations/#migrationType#s";
		var componentPath      = ReReplace( ListChangeDelims( parentDirectory, ".", "/" ), "^\.", "" );
		var migrationFiles     = DirectoryList( parentDirectory, false, "name", "*.cfc" );
		var migrations         = [];
		var versionNumberRegex = "^\d+\.\d+\.\d+$";

		for( var file in migrationFiles ){
			var versionNumber = ListChangeDelims( ReReplaceNoCase( file, "\.cfc$", "" ), ".", "-" );
			if ( ReFind( versionNumberRegex, versionNumber ) ) {
				if ( migrationType == "downgrade" && compareVersions( versionNumber, arguments.currentVersion ) <= 0 && compareVersions( versionNumber, arguments.newVersion ) > 0 ) {
					migrations.append( ListAppend( componentPath, ListChangeDelims( versionNumber, "-", "." ), "." ) );
				} else if ( migrationType == "upgrade" && compareVersions( versionNumber, arguments.currentVersion ) > 0 && compareVersions( versionNumber, arguments.newVersion ) <= 0 ) {
					migrations.append( ListAppend( componentPath, ListChangeDelims( versionNumber, "-", "." ), "." ) );
				}
			}
		}

		migrations.sort( function( a, b ){
			var aVersion = ListChangeDelims( ListLast( a, "." ), ".", "-" );
			var bVersion = ListChangeDelims( ListLast( b, "." ), ".", "-" );
			var comparison = compareVersions( aVersion, bVersion );
			return migrationType == "downgrade" ? ( comparison * -1 ) : comparison;
		} );

		for( var migration in migrations ) {
			CreateObject( migration ).run();
		}
	}

// getters and setters
	private string function _getRepositoryUrl() {
		return _repositoryUrl;
	}
	private void function _setRepositoryUrl( required string repositoryUrl ) {
		_repositoryUrl = arguments.repositoryUrl;
	}

	private string function _getPresidePath() {
		return _presidePath;
	}
	private void function _setPresidePath( required string presidePath ) {
		_presidePath = arguments.presidePath;
	}

	private any function _getSystemConfigurationService() {
		return _systemConfigurationService;
	}
	private void function _setSystemConfigurationService( required any systemConfigurationService ) {
		_systemConfigurationService = arguments.systemConfigurationService;
	}

	private any function _getApplicationReloadService() {
		return _applicationReloadService;
	}
	private void function _setApplicationReloadService( required any applicationReloadService ) {
		_applicationReloadService = arguments.applicationReloadService;
	}

	private struct function _getActiveDownloads() {
		return _activeDownloads;
	}
	private void function _setActiveDownloads( required struct activeDownloads ) {
		_activeDownloads = arguments.activeDownloads;
	}

	private any function _getLookupCache() {
		return _lookupCache;
	}
	private void function _setLookupCache( required any lookupCache ) {
		_lookupCache = arguments.lookupCache;
	}

}