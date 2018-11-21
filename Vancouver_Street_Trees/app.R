library(shiny)
library(leaflet)
library(tidyverse)
library(DT)
library(crosstalk)
library(shinyWidgets)

# load data and clean dataframe
trees <- read.csv("StreetTrees_CityWide.csv", stringsAsFactors = FALSE) %>% 
	select(lon="LONGITUDE",
		   lat="LATITUDE",
		   std_street="STD_STREET",
		   on_street="ON_STREET",
		   neighbourhood="NEIGHBOURHOOD_NAME",
		   height="HEIGHT_RANGE_ID",
		   diameter="DIAMETER",
		   date_planted="DATE_PLANTED",
		   genus="GENUS_NAME",
		   species="SPECIES_NAME",
		   common_name="COMMON_NAME") %>% 
	filter(!(lat==0)) %>% 
	transform(date_planted = as.Date(as.character(date_planted), "%Y%m%d"))


# Define UI for application
ui <- fluidPage(
    titlePanel("Vancouver's Street Trees",
               windowTitle = "Street Tree app"),
    sidebarLayout(
        sidebarPanel(
            sliderInput("heightInput", "Select tree height:",
                        min=0, max=30, value=c(3,10), pre="m"),
            sliderInput("diameterInput", "Select tree diameter:",
            						min=0, max=50, value=c(5,15), pre="m"),
            selectInput("hoodInput", "Select a neighborhood", 
            			choices=unique(trees$neighbourhood)),
            uiOutput("streetOutput"),
            plotOutput("tree_genus"),
            br(), br(),
            helpText("Data from the City of Vancouver (2018) vancouver Tree Inventory data."),
            p("Made with", a("Shiny", href = "http://shiny.rstudio.com"), ".")

        ),
        mainPanel(
        	leafletOutput("map"),
        	DTOutput("tree_data"))
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
	tree_mid <- reactive({
		trees %>% 
			filter(
				height < input$heightInput[2],
				height > input$heightInput[1],
				diameter < input$diameterInput[2],
				diameter > input$diameterInput[1],
				neighbourhood == input$hoodInput)
	})
	
			output$streetOutput <- renderUI({
			selectInput("streetInput","Select a street",
									choices=unique(tree_mid()$on_street))
		})
	
	  trees_filtered <- reactive({
	  	if (is.null(input$streetInput)) {
	  		return(NULL)
	  	}
      	trees %>% 
    		filter(
    			height < input$heightInput[2],
    			height > input$heightInput[1],
    			diameter < input$diameterInput[2],
    			diameter > input$diameterInput[1],
    			neighbourhood == input$hoodInput,
    			on_street == input$streetInput)
    	})
	  
	  # DEBUG
    icons <- reactive({
    	s <- input$tree_data_rows_selected
    	
    	getColor <- function() {
    		sapply((as.integer(rownames(trees_filtered()))), function(index) {
    			if(index %in% s) {
    				"green"
    			} else {
    				"red"
    			} })
    	}
    	
    	awesomeIcons(
    	icon = 'tree',
    	iconColor = 'black',
    	library = 'fa',
    	markerColor=getColor()
    )})
    
    
    output$map <- renderLeaflet({
    	if (is.null(trees_filtered())) {
    		return()
    	}
    	# Use leaflet() here, and only include aspects of the map that
    	# won't need to change dynamically (at least, not unless the
    	# entire map is being torn down and recreated).
    	trees_filtered() %>% 
    	leaflet() %>% addTiles() %>%
    		fitBounds(~min(lon), ~min(lat), ~max(lon), ~max(lat)) %>% 
    		addAwesomeMarkers(lng = ~lon, lat = ~lat, icon=icons(), label=~as.character(genus))
    })
    
    output$tree_genus <- renderPlot({
    	if (is.null(trees_filtered())) {
    		return()
    	}
        trees_filtered() %>% 
        	ggplot(aes(x = "", fill = factor(genus))) + 
        	geom_bar(width = 1) +
        	theme(axis.line = element_blank(), 
        		  plot.title = element_text(hjust=0.5)) +
        	labs(fill="genus", 
        		 x=NULL, 
        		 y=NULL, 
        		 title="Genus in the area", 
        		 caption="Source: Vancouver Tree inventory data 2018") +
        	coord_polar(theta = "y", start=0)
    })
    
    output$tree_data = renderDT(
    	trees_filtered(), options = list(lengthChange = FALSE))

}

# Run the application
shinyApp(ui = ui, server = server)
