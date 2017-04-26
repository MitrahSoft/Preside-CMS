/**
 * @expressionContexts formbuilderSubmission
 * @expressionCategory formbuilder
 */
component {

	property name="rulesEngineOperatorService" inject="rulesEngineOperatorService";

	/**
	 * @fbform.fieldtype      object
	 * @fbform.object         formbuilder_form
	 * @fbform.multiple       false
	 * @fbformfield.fieldtype formbuilderField
	 * @value.fieldtype       formbuilderFieldMultiChoiceValue
	 *
	 */
	private boolean function evaluateExpression(
		  required string fbform
		, required string fbformfield
		, required string value
		,          string  _all = false
	) {
		var submissionData  = payload.formbuilderSubmission.data ?: {};
		var formId          = payload.formbuilderSubmission.id   ?: "";
		var submittedValues = ( submissionData[ arguments.fbformfield ] ?: "" ).listToArray();
		var valuesToMatch   = arguments.value.listToArray();

		for( var valueToMatch in valuesToMatch ) {
			var found = submittedValues.findNoCase( valueToMatch );

			if ( found && !arguments._all ) {
				return true;
			} else if ( !found && arguments._all ) {
				return false;
			}
		}

		return arguments._all;
	}

}
