component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "evaluate_condition()", function(){
			it( "should call condition service's 'evaluate_condition()' method, passing in the condition ID and using the 'webrequest' context", function(){
				var service     = _getService();
				var conditionId = CreateUUId();

				mockConditionService.$( "evaluate_condition", true );

				expect( service.evaluate_condition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluate_condition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluate_condition[1].conditionId ?: "" ).toBe( conditionId );
				expect( mockConditionService.$callLog().evaluate_condition[1].context ?: "" ).toBe( "webrequest" );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockConditionService = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineConditionService" );

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineWebRequestService(
			  conditionService    = mockConditionService
		) );

		return service;
	}
}