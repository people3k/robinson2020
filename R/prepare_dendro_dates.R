packages <- c("magrittr",
              "tidyverse",
              "googledrive",
              "sf",
              "lwgeom"
) 
# purrr::walk(packages, devtools::install_cran) %>%
purrr::walk(packages,
            library, 
            character.only = TRUE)

# Define the Bocinsky et al. 2016 study area
SWUS_bbox <- sf::st_bbox(c(xmin = -113,
                           xmax = -105,
                           ymin = 32,
                           ymax = 38), 
                         crs = 4326) %>%
  sf::st_as_sfc() 
  

# Read in the Bocinsky et al. 2016 tree ring data
dendro_data <- 
  readr::read_csv("./data-raw/TreeRing/Bocinsky_et_al_2016_dendrochronology.csv") %>%
  # Convert to spatial object
  sf::st_as_sf(coords = c("LON","LAT"),
            crs = 4326) %>%
  # Crop to SWUS bounding box
  sf::st_intersection(SWUS_bbox) %>%
  # Convert dates to BP
  dplyr::mutate(Date_BP = 1950 - Outer_Date_AD,
                Type = ifelse(C_Level %in% c(2,3),
                              "Cutting or Near-cutting",
                              "Non-cutting")) %>%
  # drop C_Level
  dplyr::select(Seq_Number,
                Site_Number,
                Site_Name,
                Lab_Number,
                Type,
                Date_BP) %>%
  dplyr::rename(SiteID = Seq_Number) %T>%
  # Write the output to a new file (geojson)
  sf::write_sf("./data-derived/dendro_data.geojson",
               delete_dsn = TRUE)
  
# Check R/T
# sf::read_sf("./data-derived/dendro_data.geojson")
