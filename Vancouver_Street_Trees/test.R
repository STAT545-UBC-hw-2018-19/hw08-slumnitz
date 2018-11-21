library(shiny)
library(leaflet)
library(RColorBrewer)

trees <- read.csv("StreetTrees_CityWide.csv", stringsAsFactors = FALSE)

ui <- bootstrapPage(
	tags$style(type = "text/css", "html, body {width:100%;height:100%}"),
	leafletOutput("map", width = "100%", height = "100%"),
	absolutePanel(top = 10, right = 10,
								sliderInput("range", "Magnitudes", min(quakes$mag), max(quakes$mag),
														value = range(quakes$mag), step = 0.1
								),
								selectInput("colors", "Color Scheme",
														rownames(subset(brewer.pal.info, category %in% c("seq", "div")))
								),
								checkboxInput("legend", "Show legend", TRUE)
	)
)

server <- function(input, output, session) {
	
	# Reactive expression for the data subsetted to what the user selected
	filteredData <- reactive({
		trees[trees$DIAMETER >= input$range[1] & trees$DIAMETER <= input$range[2],]
	})
	
	# This reactive expression represents the palette function,
	# which changes as the user makes selections in UI.
	colorpal <- reactive({
		colorNumeric(input$colors, trees$DIAMETER)
	})
	
	output$map <- renderLeaflet({
		# Use leaflet() here, and only include aspects of the map that
		# won't need to change dynamically (at least, not unless the
		# entire map is being torn down and recreated).
		leaflet(trees) %>% addTiles() %>%
			fitBounds(~min(LONGITUDE), ~min(LATITUDE), ~max(LONGITUDE), ~max(LATITUDE))
	})
	
	# Incremental changes to the map (in this case, replacing the
	# circles when a new color is chosen) should be performed in
	# an observer. Each independent set of things that can change
	# should be managed in its own observer.
	observe({
		pal <- colorpal()
		
		leafletProxy("map", data = filteredData()) %>%
			clearShapes() %>%
			addCircles(radius = ~10^DIAMETER/10, weight = 1, color = "#777777",
								 fillColor = ~pal(DIAMETER), fillOpacity = 0.7, popup = ~paste(DIAMETER)
								 )
	})
	
	# Use a separate observer to recreate the legend as needed.
	observe({
		proxy <- leafletProxy("map", data = trees)
		# Remove any existing legend, and only if the legend is
		# enabled, create a new one.
		proxy %>% clearControls()
		if (input$legend) {
			pal <- colorpal()
			proxy %>% addLegend(position = "bottomright",
													pal = pal, values = ~DIAMETER
			)
		}
	})
}

shinyApp(ui, server)