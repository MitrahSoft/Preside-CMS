component output=false {

	property name="assetManagerService" inject="assetManagerService";

	public function index( event, rc, prc ) output=false {
		announceInterception( "preDownloadFile" );

		var storageProvider = rc.storageProvider ?: "";
		var storagePath     = rc.storagePath     ?: "";
		var filename        = rc.filename        ?: ListLast( storagePath, "/" );

		if ( !Len( Trim( storageProvider ) ) || !Len( Trim( storagePath ) ) ) {
			event.notFound();
		}

		try {
			storageProvider = getModel( storageProvider );
		} catch( any e ) {
			event.notFound();
		}

		if ( !storageProvider.objectExists( storagePath ) ) {
			event.notFound();
		}

		var type = assetManagerService.getAssetType( name=ListLast( filename, "." ), throwOnMissing=true );
		var etag = LCase( Hash( SerializeJson( storageProvider.getObjectInfo( storagePath ) ) ) );

		_doBrowserEtagLookup( etag );

		var fileBinary = storageProvider.getObject( storagePath );

		if ( type.serveAsAttachment ) {
			cfheader( name="Content-Disposition", value="attachment; filename=""#filename#""" );
		} else {
			cfheader( name="Content-Disposition", value="inline; filename=""#filename#""" );
		}

		announceInterception( "onDownloadFile", {
			  storageProvider = storageProvider
			, storagePath     = storagePath
			, filename        = filename
			, type            = type
			, fileBinary      = fileBinary
		} );

		cfheader( name="etag", value=etag );
		cfheader( name="cache-control", value="max-age=31536000" );
		cfcontent(
			reset    = true,
			variable = fileBinary,
			type     = type.mimeType );
		abort;
	}

// private helpers
	private string function _doBrowserEtagLookup( required string etag ) output=false {
		if ( ( cgi.http_if_none_match ?: "" ) == arguments.etag ) {
			announceInterception( "onReturnFile304", { etag = arguments.etag } );
			cfcontent( reset=true );cfheader( statuscode=304, statustext="Not Modified" );abort;
		}
	}
}