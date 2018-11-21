library(shiny)
library(leaflet)
library(tidyverse)
library(forecast)
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


# Define UI for application that draws a histogram
ui <- fluidPage(
    titlePanel("Vancouver's Street Trees",
               windowTitle = "Street Tree app"),
    sidebarLayout(
        sidebarPanel(
            sliderInput("heightInput", "Select tree height",
                        min=0, max=20, value=c(1, 3), pre="m"),
            radioButtons("typeInput", "Select a tree genus",
                         choices = unique(trees$genus), # 
                         selected = "SALIX")

        ),
        mainPanel(
        	leafletOutput("map"),
            plotOutput("tree_genus"),
            tableOutput("tree_data")
            )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    trees_filtered <- reactive({ #needed for update
        trees %>%
            filter(
                height < input$heightInput[2], #
                height > input$heightInput[1],
                genus == input$typeInput)})

    output$map <- renderLeaflet({
    	# Use leaflet() here, and only include aspects of the map that
    	# won't need to change dynamically (at least, not unless the
    	# entire map is being torn down and recreated).
    	leaflet(trees) %>% addTiles() %>%
    		fitBounds(~min(lon), ~min(lat), ~max(lon), ~max(lat))
    })
    
    output$tree_genus <- renderPlot({
        trees_filtered %>% 
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
    
    output$tree_data <- renderTable(trees_filtered())

}

# Run the application
shinyApp(ui = ui, server = server)
