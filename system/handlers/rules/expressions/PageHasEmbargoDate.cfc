/**
 * Expression handler for "Current page has/does not have an embargo date"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
		boolean _posesses = true
	) {
		var embargo    = payload.page.embargo_date ?: "";
		var hasEmbargo = IsDate( embargo );

		return _posesses ? hasEmbargo : !hasEmbargo;
	}

}