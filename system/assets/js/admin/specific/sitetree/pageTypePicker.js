( function( $ ){

	var linkWasClicked = function( eventTarget ){
		return $.inArray( eventTarget.nodeName, ['A','INPUT','BUTTON','TEXTAREA','SELECT'] ) >= 0
		    || $( eventTarget ).parents( 'a:first,input:first,button:first,textarea:first,select:first' ).length;
	};


	$( 'body' ).on( "click", ".page-type-picker .page-type", function( e ){
		if ( !linkWasClicked( e.target ) ) {
			var $firstLink = $( this ).find( 'a:first' );

			if ( $firstLink.length ) {
				e.preventDefault();
				$firstLink.get(0).click();
			}
		}
	} );

	xOffset = 10;
	yOffset = 30;

	$( 'body' ).on( "mouseover", ".screenshot", function( e ){
		
		if ($(this).attr('data-mainImgsrc').split('/')[4].length) {
			getMainImage = "<img src='"+ $(this).attr('data-mainImgsrc') +"' width='160px' height='150px' />";
		} else {
			getMainImage  = "No Main Image";
		}

		$("body").append("<p id='screenshot'>"+getMainImage+"</p>");
		$("#screenshot")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px")
			.css({position: 'absolute',border: '1px solid #ccc',background: '#333',padding: '5px',color: '#fff'})
			.fadeIn("fast");
	});

	$( 'body' ).on( "mouseout", ".screenshot", function( e ){
		$("#screenshot").remove();
    });	

	$( 'body' ).on( "mousemove", ".screenshot", function( e ){
		$("#screenshot")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px")
			.css({position: 'absolute',border: '1px solid #ccc',background: '#333',padding: '5px',color: '#fff'});
	});

} )( presideJQuery );