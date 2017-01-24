/**
 * @singleton
 *
 */
component {

// CONSTRUCTOR
	/**
	* @baseEngine.inject baseEngine
	*/
	public any function init( required any baseEngine ) {
		_setBaseEngine( arguments.baseEngine );
		_setLibPath( ExpandPath( "/preside/system/services/security/antisamylib" ) );
		_setupPolicyFiles();
		_setupAntiSamy();

		return this;
	}

// PUBLIC API
	public any function clean( required string input, string policy="myspace" ) {
		var antiSamyResult = _getAntiSamy().scan( arguments.input, _getPolicyFile( arguments.policy ) );
		var cleanHtml      = antiSamyResult.getCleanHtml();

		return _removeUnwantedCleanses( cleanHtml, arguments.policy );
	}

// PRIVATE HELPERS
	private void function _setupPolicyFiles() {
		var libPath = _getLibPath();

		_setPolicyFiles ( {
			  antisamy = libPath & '/antisamy-anythinggoes-1.4.4.xml'
			, ebay     = libPath & '/antisamy-ebay-1.4.4.xml'
			, myspace  = libPath & '/antisamy-myspace-1.4.4.xml'
			, slashdot = libPath & '/antisamy-slashdot-1.4.4.xml'
			, tinymce  = libPath & '/antisamy-tinymce-1.4.4.xml'
		} );
	}

	private void function _setupAntiSamy() {
		_setAntiSamy( _getBaseEngine().getAntiSamyObject( _getLibPath() ) );
	}

	private array function _listJars( required string directory ) {
		return ;
	}

	private string function _getPolicyFile( required string policy ) {
		var policies = _getPolicyFiles();

		if ( structKeyExists(policies, arguments.policy) )
			return policies[ arguments.policy ];
		else
			throw( type="preside.antisamyservice.policy.not.found", message="The policy [#arguments.policy#] was not found. Existing policies: '#SerializeJson( policies.keyArray() )#" );
	}

	private string function _removeUnwantedCleanses( required string tooCleanString, required string policy ) {
		var antiSamyResult   = _getAntiSamy().scan( "&", _getPolicyFile( arguments.policy ) );
		var cleanedAmpersand = antiSamyResult.getCleanHtml();
		var uncleaned        = arguments.tooCleanString;

		if ( cleanedAmpersand != "&" ) {
			uncleaned = uncleaned.replace( cleanedAmpersand, "&", "all" );
		}

		return uncleaned;
	}

// GETTERS AND SETTERS
	private string function _getLibPath() {
		return _libPath;
	}
	private void function _setLibPath( required string libPath ) {
		_libPath = arguments.libPath;
	}

	private struct function _getPolicyFiles() {
		return _policyFiles;
	}
	private void function _setPolicyFiles( required struct policyFiles ) {
		_policyFiles = arguments.policyFiles;
	}

	private any function _getAntiSamy() {
		return _antiSamy;
	}
	private void function _setAntiSamy( required any antiSamy ) {
		_antiSamy = arguments.antiSamy;
	}

	private any function _getBaseEngine() {
		return _baseEngine;
	}
	private void function _setBaseEngine( required any baseEngine ) {
		_baseEngine = arguments.baseEngine;
	}
}