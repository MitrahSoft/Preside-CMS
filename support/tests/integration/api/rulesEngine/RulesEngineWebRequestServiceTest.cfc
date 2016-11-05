component extends="resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "evaluate_condition()", function(){
			it( "should call condition service's 'evaluate_condition()' method, passing in the condition ID and using the 'webrequest' context", function(){
				var service     = _getService();
				var conditionId = CreateUUId();

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( {} );
				mockConditionService.$( "evaluate_condition", true );
				mockLoginService.$( "getLoggedInUserDetails", {} );

				expect( service.evaluate_condition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluate_condition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluate_condition[1].conditionId ?: "" ).toBe( conditionId );
				expect( mockConditionService.$callLog().evaluate_condition[1].context ?: "" ).toBe( "webrequest" );
			} );

			it( "should call condition service's 'evaluate_condition()' method, passing in details about the current page in the payload", function(){
				var service     = _getService();
				var dummyPage   = { blah=CreateUUId(), test=true };
				var conditionId = CreateUUId();

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( dummyPage );
				mockConditionService.$( "evaluate_condition", true );
				mockLoginService.$( "getLoggedInUserDetails", {} );

				expect( service.evaluate_condition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluate_condition.len() ).toBe( 1 );
				expect( mockConditionService.$callLog().evaluate_condition[1].payload.page ?: {} ).toBe( dummyPage );
			} );

			it( "should pass information about the logged in user in the evaluate_condition payload", function(){
				var service     = _getService();
				var conditionId = CreateUUId();
				var dummyUser   = { id=CreateUUId(), login_id="test" };

				mockRequestContext.$( "getValue" ).$args( name="presidePage", defaultValue={}, private=true ).$results( {} );
				mockConditionService.$( "evaluate_condition", true );
				mockLoginService.$( "getLoggedInUserDetails", dummyUser );

				expect( service.evaluate_condition( conditionId ) ).toBeTrue();
				expect( mockConditionService.$callLog().evaluate_condition[1].payload.user ?: {} ).toBe( dummyUser );
			} );
		} );
	}

// PRIVATE HELPERS
	private any function _getService() {
		mockConditionService = CreateEmptyMock( "preside.system.services.rulesEngine.RulesEngineConditionService" );
		mockLoginService     = CreateEmptyMock( "preside.system.services.websiteUsers.WebsiteLoginService" );
		mockRequestContext   = CreateStub();

		var service = createMock( object=new preside.system.services.rulesEngine.RulesEngineWebRequestService(
			  conditionService    = mockConditionService
			, websiteLoginService = mockLoginService
		) );

		service.$( "$getRequestContext", mockRequestContext );

		return service;
	}
}