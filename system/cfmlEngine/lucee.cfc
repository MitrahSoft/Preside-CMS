/**
*
* @file
* @author
* @description
*
*/

component output="false" displayname=""  {

	public function deleteSchedule(taskName){
		cfschedule( action="delete", task=arguments.taskName );

		return true;
	}

	public function getFKRules(){
		return { "0"  = "cascade", "2" = "set null" };
	}

	public function getAntiSamyObject(jarFolderPath){
		var jars = DirectoryList( arguments.jarFolderPath, false, "path", "*.jar" );
		return CreateObject( "java", "org.owasp.validator.html.AntiSamy", jars ) ;
	}

}