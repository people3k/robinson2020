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

# Define the Phoenix Basin
# Defined as SW AZ counties, using the National Map small scale data
# "https://prd-tnm.s3.amazonaws.com/StagedProducts/Small-scale/data/Boundaries/countyp010g.gdb_nt00933.tar.gz" %>%
#   download.file(destfile="../data-raw/countyp010g.gdb_nt00933.tar.gz", 
#                 mode='wb')
# untar("../data-raw/countyp010g.gdb_nt00933.tar.gz",
#       exdir="../data-raw/countyp010g")
phx_basin <- "./data-raw/countyp010g/countyp010g.gdb/" %>%
  sf::st_read() %>%
  dplyr::filter(NAME %in% 
                  c("Maricopa",
                    "Pinal",
                    "Pima")) %>%
  sf::st_transform(4326) %>%
  sf::st_union()

# Read in the Bocinsky et al. 2016 tree ring data
radiocarbon_data <- #readr::read_csv("./data-raw/Radiocarbon/14C_Raw.csv") %>%
  readr::read_csv("./data-raw/Radiocarbon/0403_sbox_clean.csv") %>%
  # Convert to spatial object
  sf::st_as_sf(coords = c("Long","Lat"),
               crs = 4326) %>%
  # Crop to SWUS bounding box
  sf::st_intersection(SWUS_bbox) %>%
  # Remove Phoenix Basin dates
  sf::st_difference(phx_basin) %>%
  # Select salient columns
  dplyr::select(labnumber,
                date,
                sd,
                #diff,
                #d13,
                #mat,
                #Source,
                Site,
                SiteID) %>%
  dplyr::rename(Lab_Number = labnumber,
                Date_BP = date,
                SD = sd,
                # Diff = diff,
                # Material = mat,
                Site_Number = Site) %>%
  sf::st_intersection("./data-raw/countyp010g/countyp010g.gdb/" %>%
                        sf::st_read() %>%
                        sf::st_transform(4326) %>%
                        dplyr::mutate(County = paste(NAME, STATE, sep = ", ")) %>%
                        dplyr::select(County)) %T>%
  # Write the output to a new file (geojson)
  sf::write_sf("./data-derived/radiocarbon_data.geojson",
               delete_dsn = TRUE)

# Check R/T
# sf::read_sf("./data-derived/radiocarbon_data.geojson")
