/**
*
* @file  /D/Projects/CF_2016/presidecf2016/presideCore/system/services/cfmlEngines/lucee.cfc
* @author  
* @description
*
*/

component output="false" displayname=""  {

	public function deleteSchedule(taskName){
		cfschedule( action="delete", task=arguments.taskName );
	}

	return true;
}