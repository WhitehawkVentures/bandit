function show_chart(title, url, category) {
   $.get(url, function(data) { show_chart_data(title, data, category) });
}

function show_chart_data(title, data, category) {
   var options = {
      chart: { renderTo: 'totals_gcontainer_' + category },
      title: { text: title },
      rangeSelector: { selected: 5 },
      subtitle: { text: "participant / conversion totals" },
      yAxis: { title: { text: "people" } },
      series: []
   };

   var percent_options = {
      chart: { renderTo: 'percents_gcontainer_' + category },
      title: { text: title },
      rangeSelector: { selected: 5 },
      subtitle: { text: "conversion percents" },
      yAxis: { title: { text: "% converted" } },
      series: []
   };

   var series_c = null;
   var series_p = null;
   var series_percent = null;
   $.each(data.split('\n'), function(lineNo, line) {
	     var items = line.split("\t");
	     var ctitle = items[0] + " conversions";
	     var ptitle = items[0] + " participants";
	     var percent_title = items[0] + " conversion %";
	     if(series_c == null || series_c.name != ctitle) {
		if(series_c != null) { options.series.push(series_p); options.series.push(series_c); percent_options.series.push(series_percent); }
		series_c = { data: [], name: ctitle };
		series_p = { data: [], name: ptitle };
		series_percent = { data: [], name: percent_title, yDecimals: 2 };
	     }
	     var date = Date.UTC(parseInt(items[1]), parseInt(items[2])-1, parseInt(items[3]), parseInt(items[4]));
	     var participants = parseFloat(items[5]);
	     var conversions = parseFloat(items[6]);
         if (participants == 0) {
            var conversion_percent = 0;
         } else {
	        var conversion_percent = Math.round((conversions / participants) * 100 * 10000) / 10000;
         }
	     series_p.data.push([date, participants]);
	     series_c.data.push([date, conversions]);
	     series_percent.data.push([date, conversion_percent]);
          });
   options.series.push(series_p);
   options.series.push(series_c);
   percent_options.series.push(series_percent);
//   var chart = new Highcharts.StockChart(options);
   var charttwo = new Highcharts.StockChart(percent_options);
}
