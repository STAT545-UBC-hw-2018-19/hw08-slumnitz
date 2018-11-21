library(shiny)
library(leaflet)
library(tidyverse)
library(DT)

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
	# filter 0 lat values and transform date integer to proper date.


# Define UI for application
ui <- fluidPage(
    titlePanel("Vancouver's Street Trees",
               windowTitle = "Street Tree app"),
    sidebarLayout(
        sidebarPanel(
        	  # height
            sliderInput("heightInput", "Select tree height:",
                        min=0, max=30, value=c(3,10), pre="m"),
            # diameter
            sliderInput("diameterInput", "Select tree diameter:",
            						min=0, max=50, value=c(5,15), pre="m"),
            # neighbourhood
            selectInput("hoodInput", "Select a neighbourhood", 
            			choices=unique(trees$neighbourhood), selected="KITSILANO"),
            # street according dependant on neighbourhood
            uiOutput("streetOutput"),
            # plot tree genus distribution
            plotOutput("tree_genus"),
            br(),
            # Data Reference
            helpText("Data from the City of Vancouver (2018) vancouver Tree Inventory data."),
            p("Access data", a("here", href = "https://data.vancouver.ca/datacatalogue/streettrees.htm"), "."),
            # add shiny reference
            p("Made with", a("Shiny", href = "http://shiny.rstudio.com"), ".")

        ),
        mainPanel(
        	leafletOutput("map"), 
        	DTOutput("tree_data"))
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
	# function needed to update street Input
	tree_mid <- reactive({
		trees %>% 
			filter(
				height < input$heightInput[2],
				height > input$heightInput[1],
				diameter < input$diameterInput[2],
				diameter > input$diameterInput[1],
				neighbourhood == input$hoodInput)
	})
	
			# define Street inpout dependent on neighbourhood choice
			output$streetOutput <- renderUI({
			selectInput("streetInput","Select a street",
									choices=unique(tree_mid()$on_street))
		})
	
		# filter input data dependent on choices
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
	  
	  # Add color dependent on selection in table
    icons <- reactive({
    	s <- input$tree_data_rows_selected # selection of table
    	getColor <- function() {
    		sapply((as.integer(rownames(trees_filtered()))), function(index) {
    			if(index %in% s) {
    				"red"
    			} else {
    				"green"
    			} })
    	}
    	
    	# create Icon
    	awesomeIcons(
    	icon = 'tree',
    	iconColor = 'black',
    	library = 'fa',
    	markerColor=getColor()
    )})
    
    # create map
    output$map <- renderLeaflet({
    	if (is.null(icons())) {
    		return()
    	}
    	
    	trees_filtered() %>% 
    	leaflet() %>% addTiles() %>%
    		fitBounds(~min(lon), ~min(lat), ~max(lon), ~max(lat)) %>% 
    		addAwesomeMarkers(lng = ~lon, lat = ~lat, icon=icons(), label=~as.character(genus))
    })
    
    # create Pie chart
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
    	trees_filtered(), rownames = FALSE, extensions = 'Buttons', 
    	options = list(dom = 'Bfrtip', buttons = list(list(extend = 'colvis', columns = c(0, 1, 2, 3,9))),
    								 lengthChange = FALSE, scrollX= TRUE),
    						class = "compact")

}

# Run the application
shinyApp(ui = ui, server = server)
