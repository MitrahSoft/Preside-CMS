/**
 * @presideService true
 * @singleton      true
 *
 */
component extends="AbstractHeartBeat" {

	/**
	 * @adhocTaskmanagerService.inject adhocTaskmanagerService
	 *
	 */
	public function init( required any adhocTaskmanagerService ){
		super.init(
			  threadName   = "Preside Adhoc Task Heartbeat"
			, intervalInMs = 1000
		);

		_setAdhocTaskmanagerService( arguments.adhocTaskmanagerService );

		return this;
	}

	// PUBLIC API METHODS
	public void function run() {
		try {
			_getAdhocTaskmanagerService().runScheduledTasks();
		} catch( any e ) {
			$raiseError( e );
		}
	}

	public void function startInNewRequest() {
		var startUrl = $getRequestContext().buildLink( linkTo="taskmanager.runtasks.startAdhocTaskManagerHeartbeat" );

		thread name=CreateUUId() startUrl=startUrl {
			try {
				sleep( 5000 );
				http method="post" url=startUrl timeout=2 throwonerror=true;
			} catch( any e ) {
				$raiseError( e );
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getAdhocTaskmanagerService() {
		return _taskmanagerService;
	}
	private void function _setAdhocTaskmanagerService( required any adhocTaskmanagerService ) {
		_taskmanagerService = arguments.adhocTaskmanagerService;
	}
}