component output="false" extends="tests.resources.HelperObjects.PresideTestCase" {

// SETUP, TEARDOWN, ETC.
	function setup() {
		super.setup();

		transformer = new preside.system.services.assetManager.AssetTransformer(
			imageManipulationService = new preside.system.services.assetManager.imageManipulationService()
		);
	}

// TESTS
	function test01_resize_shouldThrowAnInformativeError_whenPassedAssetIsNotAnImage() output=false {
		var errorThrown = false;
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testfile.txt')#" );

		try {
			transformer.resize( assetBinary, 100, 100 );
		} catch ( "assetTransformer.resize.notAnImage" e ) {
			errorThrown = true;
		} catch ( any e ) {
			super.fail( "Expected an error of type [assetTransformer.resize.notAnImage] but received type [#e.type#] with message [#e.message#] instead" );
		}

		super.assert( errorThrown, "An informative error was not thrown" );
	}

	function test02_resize_shouldReturnResizedBinaryImage_withSpecifiedWidth_whenNoHeightSpecified() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testlandscape.jpg')#" );
		var resized     = transformer.resize(
			  asset = assetBinary
			, width = 100
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 100, imgInfo.width );
		super.assertEquals( 71 , imgInfo.height );
	}

	function test03_resize_shouldReturnResizedBinaryImage_withSpecifiedHeight_whenNoWidthSpecified() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testlandscape.jpg')#" );
		var resized     = transformer.resize(
			  asset  = assetBinary
			, height = 200
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 200, imgInfo.height );
		super.assertEquals( 283, imgInfo.width );
	}

	function test04_resize_shouldReturnResizedBinaryImage_withSpecifiedHeightAndWidth() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testlandscape.jpg')#" );

		var resized     = transformer.resize(
			  asset  = assetBinary
			, height = 200
			, width  = 300
		);

		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 200, imgInfo.height );
		super.assertEquals( 300, imgInfo.width );
	}

	function test05_resize_shouldReturnCroppedAndResizedBinaryImage_whenPassedHeightAndWidthThatDoNotMatchAspectRatio_andWhenMaintainAspectRatioIsSetToTrue() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testportrait.jpg')#" );
		var resized     = transformer.resize(
			  asset  = assetBinary
			, height = 400
			, width  = 400
			, maintainAspectRatio = true
		);
		var imgInfo     = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 400, imgInfo.height );
		super.assertEquals( 400, imgInfo.width );
	}

	function test06_shrinkToFit_shouldLeaveImageUntouched_whenImageAlreadySmallerThanDimensionsPassed() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testportrait.jpg')#" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = transformer.shrinkToFit(
			  asset  = assetBinary
			, height = imgInfo.height + 1
			, width  = imgInfo.width + 1
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo, newImgInfo );
	}

	function test07_shrinkToFit_shouldScaleImageDownByXAxis_whenOnlyWidthIsLargerThanPassedDimensions() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testportrait.jpg')#" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = transformer.shrinkToFit(
			  asset  = assetBinary
			, height = imgInfo.height + 10
			, width  = imgInfo.width - 10
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo.width - 10, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height );
	}

	function test08_shrinkToFit_shouldScaleImageDownByYAxis_whenOnlyHeightIsLargerThanPassedDimensions() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testportrait.jpg')#" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = transformer.shrinkToFit(
			  asset  = assetBinary
			, height = imgInfo.height - 10
			, width  = imgInfo.width + 10
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( imgInfo.height - 10, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width );
	}

	function test09_shrinkToFit_shouldScaleImageDownByYAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andHeightTransformationWouldReduceWidthToWithinMaxWidth() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testportrait.jpg')#" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = transformer.shrinkToFit(
			  asset  = assetBinary
			, height = 100
			, width  = 100
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 100, newImgInfo.height );
		super.assert( newImgInfo.width < imgInfo.width && newImgInfo.width < 100 );
	}

	function test10_shrinkToFit_shouldScaleImageDownByXAxis_whenBothHeightAndWidthAreLargerThanPassedDimensions_andWidthTransformationWouldReduceHeightToWithinMaxHeight() output=false {
		var assetBinary = FileReadBinary( "#expandPath('/tests/resources/assetManager/testlandscape.jpg')#" );
		var imgInfo     = ImageInfo( ImageNew( assetBinary ) );
		var resized     = transformer.shrinkToFit(
			  asset  = assetBinary
			, height = 400
			, width  = 400
		);
		var newImgInfo  = ImageInfo( ImageNew( resized ) );

		super.assertEquals( 400, newImgInfo.width );
		super.assert( newImgInfo.height < imgInfo.height && newImgInfo.height < 400 );
	}
}