$(document).ready(function() {
	setTimeout(function() {
		/**
		A hack to update the labels on the slider using a 'prettify' functino
		**/

		function get_month_abbreviation(num) {
			var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
		    var index = Math.max(Math.min(num - 1, 11), 0);
		    return months[index];
		}

		$(".js-range-slider").each(function() {
			$(this).data("ionRangeSlider").update({
				prettify: get_month_abbreviation
			})
		});

	}, 10);
});