google.charts.load('current', {packages: ['corechart', 'line', 'table']});
google.charts.setOnLoadCallback(draw);

function draw() {
  classNameRegex = /[^a-z0-9]+/g;

  currentGroup = null;
  currentGroupDiv = null;
  chart_configs.forEach((config) => {
    var dataTable = new google.visualization.DataTable();
    config["columns"].forEach((column) => {
      dataTable.addColumn(column["type"], column["label"]);
    });
    if (config["columns"][0]["type"] == "date") {
      config["rows"].forEach((row) => {
        row[0] = new Date(row[0]);
      });
    }
    dataTable.addRows(config["rows"]);

    if (currentGroup != config["group"]) {
      currentGroup = config["group"];

      var h1 = document.createElement('h1');
      h1.innerHTML = config["group"];
      document.body.appendChild(h1);

      currentGroupDiv = document.createElement('div');
      var className = config["group"].toLowerCase().replaceAll(classNameRegex, "-").replace(/-$/, '');
      currentGroupDiv.className = `group ${className}`
      document.body.appendChild(currentGroupDiv);
    }

    var chartContainerDiv = document.createElement('div');
    var className = config["name"].toLowerCase().replaceAll(classNameRegex, "-").replace(/-$/, '');
    chartContainerDiv.className = `chart-container ${className}`
    currentGroupDiv.appendChild(chartContainerDiv);

    var h2 = document.createElement('h2');
    h2.innerHTML = config["name"];
    chartContainerDiv.appendChild(h2);

    var chartDiv = document.createElement('div');
    chartDiv.className = ".chart"
    chartContainerDiv.appendChild(chartDiv);

    if (config["type"] == "line") {
      var chart = new google.visualization.LineChart(chartDiv);
      chart.draw(dataTable, config["options"]);
    } else if (config["type"] == "table") {
      var table = new google.visualization.Table(chartDiv);
      table.draw(dataTable, config["options"]);
    } else {
      throw `Invalid chart type: ${config["type"]}`
    }
  });
}
