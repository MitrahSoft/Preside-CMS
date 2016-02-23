component displayname="ImageMagick"  {

	public any function init(
		 required string  path
		, 		  numeric timeout = 30
	) {
		_setExecutablePath( arguments.path );
		_setTimeout( arguments.timeout );
		return this;
	}

	public binary function resize(
		  required binary  asset
		,          numeric width               = 0
		,          numeric height              = 0
		,          string  quality             = "highPerformance"
		,          boolean maintainAspectRatio = false
		,          struct  assetProperties     =  {}
	) output=false {
		var image              = "";
		var currentImageInfo   = {};
		var tmpFilePath        = GetTempDirectory() & "/" & arguments.assetProperties.filename;
		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.resize.notAnImage" );
		}

		currentImageInfo = ImageInfo( image );

		var imageMagickFile = "";

		if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {
			imageMagickFile   = imageMagickResize(
				  sourceFile      = assetProperties.sourceFile
				, destinationFile = tmpFilePath
				, width           = arguments.width
				, height          = arguments.height
				, expand          = maintainAspectRatio
				, crop            = maintainAspectRatio
			);
		}
		image = FileReadBinary( imageMagickFile );

		return ImageGetBlob( image );
	}

	public binary function pdfPreview(
		  required binary asset
		,          string scale
		,          string resolution
		,          string format
		,          string pages
		,          string transparent
		,          struct assetProperties =  {}
	) {
		var imagePrefix               = CreateUUId();
		var tmpFilePath               = GetTempDirectory() & "/" & imagePrefix & ".jpg";
		assetProperties.fileName      = replaceNoCase(assetProperties.fileName, ".pdf", ".jpg");
		execArgs.args                 = '-density 100 -colorspace rgb "#arguments.assetProperties.sourceFile#[0]" "#tmpFilePath#"';
		assetProperties.sourceFile    = tmpFilePath;
		execute( argumentCollection = execArgs );
		return FileReadBinary( tmpFilePath );
	}

	public binary function shrinkToFit(
		  required binary  asset
		, required numeric width
		, required numeric height
		,          string  quality             = "highPerformance"
		,          struct  assetProperties     =  {}
	) output=false {

		var image            = "";
		var currentImageInfo = {};
		var tmpFilePath      = GetTempDirectory() & "/" & arguments.assetProperties.filename;

		try {
			image = ImageNew( arguments.asset );
		} catch ( "java.io.IOException" e ) {
			throw( type="AssetTransformer.shrinkToFit.notAnImage" );
		}

		if( !structIsEmpty( arguments.assetProperties ) ){
			currentImageInfo.height = arguments.assetProperties.height ?: 0;
			currentImageInfo.width  = arguments.assetProperties.width  ?: 0;
		} else {
			currentImageInfo = ImageInfo( image );
		}

		var imageMagickFile = "";

		if ( currentImageInfo.width == arguments.width && currentImageInfo.height == arguments.height ) {
			return arguments.asset;
		} else {
			var imageMagickFile   = imageMagickResize(
				  sourceFile      = assetProperties.sourceFile
				, destinationFile = tmpFilePath
				, width           = arguments.width
				, height          = arguments.height
				, expand          = true
				, crop            = false
			);
		}
		image = FileReadBinary( imageMagickFile );

		return ImageGetBlob( image );
	}

	public string function imageMagickResize(
		  required string  sourceFile
		, required string  destinationFile
		, required numeric width
		, required numeric height
		,          boolean expand    = false
		,          boolean crop      = false
		,          string  gravity   = 'center'
	) {
		var execArgs.args    = '"#arguments.sourceFile#" -resize #arguments.width#x#arguments.height#';

    	if ( arguments.expand ) {
    		if ( arguments.crop ) {
    			execArgs.args &= "^";
    		}
    		execArgs.args &= " -gravity #arguments.gravity# -extent #arguments.width#x#arguments.height#";
    	}

    	execArgs.args &= " " & '"#arguments.destinationFile#"';
       	execute( argumentCollection = execArgs );

    	return arguments.destinationFile;
	}

	private string function execute(
		required string args
	) {
	    var result = "";
		 cfexecute(
				   name      = "#_getExecutablePath()#"
				  ,arguments = "#arguments.args#"
				  ,timeout   = "#_getTimeout()#"
				  ,variable  = "result" );
		 return result;
	}

	private string function _getExecutablePath() {
		return _executablePath;
	}

	private void function _setExecutablePath(
		required string executablePath
	) {
		_executablePath = arguments.executablePath;
	}

	private numeric function _getTimeout() {
		return _timeout;
	}

	private void function _setTimeout(
		required string timeout
	) {
		_timeout = arguments.timeout;
	}
}