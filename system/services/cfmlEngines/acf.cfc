/**
*
* @file  /D/Projects/CF_2016/presidecf2016/presideCore/system/services/cfmlEngines/acf.cfc
* @author
* @description
*
*/

component output="false" displayname=""  {

	public function deleteSchedule(taskName){
		cfschedule( action="list", task=arguments.taskName, result="result" );
		if( result.recordCount )
			cfschedule( action="delete", task=arguments.taskName );

		return true;
	}
}