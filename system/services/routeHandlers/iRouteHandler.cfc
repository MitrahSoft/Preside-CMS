interface {
	public boolean function match       ( required string path     , required any event );
	public void    function translate   ( required string path     , required any event );
	public boolean function reverseMatch( required struct buildArgs, required any event );
	public string  function build       ( required struct buildArgs, required any event );
}